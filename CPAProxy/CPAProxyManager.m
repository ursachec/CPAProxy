//  CPAProxyManager.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAProxyManager.h"
#import "CPAThread.h"
#import "CPAConfiguration.h"
#import "CPASocketManager.h"
#import "CPAProxyManager+TorCommands.h"
#import "CPAProxyTorCommands.h"
#import "CPAProxyResponseParser.h"
#import "CPAProxyTorCommandConstants.h"

NSString * const CPAProxyDidStartSetupNotification = @"com.cpaproxy.setup.start";
NSString * const CPAProxyDidFailSetupNotification = @"com.cpaproxy.setup.fail";
NSString * const CPAProxyDidFinishSetupNotification = @"com.cpaproxy.setup.finish";

NSString * const CPAErrorDomain = @"CPAErrorDomain";

const NSTimeInterval CPAConnectToTorSocketDelay = 0.5;
const NSTimeInterval CPAGetBootstrapProgressInterval = 2.0;
const NSTimeInterval CPATimeoutDelay = 25;

const NSInteger CPABootstrapProgressPercentageDone = 100;

typedef NS_ENUM(NSUInteger, CPAErrors) {
    CPAErrorTorrcOrGeoipPathNotSet = 0,
    CPAErrorTorAuthenticationFailed,
    CPAErrorSocketOpenFailed,
    CPAErrorTorSetupTimedOut,
};

// Function definitions to get version numbers of dependencies to avoid including headers
/** Returns OpenSSL version */
extern const char *SSLeay_version(int type);
/** Returns Libevent version */
extern const char *event_get_version(void);
/** Returns Tor version */
extern const char *get_version(void);

typedef NS_ENUM(NSUInteger, CPAControlPortStatus) {
    CPAControlPortStatusClosed = 0,
    CPAControlPortStatusConnecting,
    CPAControlPortStatusAuthenticated
};

@interface CPAProxyManager () <CPASocketManagerDelegate>
@property (nonatomic, strong, readwrite) CPASocketManager *socketManager;
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@property (nonatomic, strong, readwrite) CPAThread *torThread;

@property (nonatomic, strong, readwrite) NSTimer *bootstrapTimer;
@property (nonatomic, strong, readwrite) NSTimer *timeoutTimer;
@property (nonatomic, copy, readwrite) CPABootstrapCompletionBlock completionBlock;
@property (nonatomic, copy, readwrite) CPABootstrapProgressBlock progressBlock;
@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic) dispatch_queue_t workQueue;

@property (nonatomic, readwrite) CPAStatus status;
@property (nonatomic, readwrite) CPAControlPortStatus controlPortStatus;
@end

@implementation CPAProxyManager

+ (instancetype)proxyWithConfiguration:(CPAConfiguration *)configuration
{
    CPAThread *torThread = [[CPAThread alloc] initWithConfiguration:configuration];
    return [[CPAProxyManager alloc] initWithConfiguration:configuration torThread:torThread];
}

- (instancetype)initWithConfiguration:(CPAConfiguration *)configuration
{
    CPAThread *torThread = [[CPAThread alloc] initWithConfiguration:configuration];
    return [[CPAProxyManager alloc] initWithConfiguration:configuration torThread:torThread];
}

- (instancetype)initWithConfiguration:(CPAConfiguration *)configuration
                            torThread:(CPAThread *)torThread
{
    self = [super init];
    if(!self) return nil;
    
    self.socketManager = [[CPASocketManager alloc] initWithDelegate:self];
    
    self.controlPortStatus = CPAControlPortStatusClosed;
    self.status = CPAStatusClosed;
    
    self.configuration = configuration;
    self.torThread = torThread;
    
    NSString *label = [NSString stringWithFormat:@"%@.work.%p", [self class], self];
    self.workQueue = dispatch_queue_create([label UTF8String], 0);
    
    return self;
}

- (void)dealloc
{
    [self.torThread cancel];
    self.torThread = nil;
}

#pragma mark - 

- (void)setupWithCompletion:(CPABootstrapCompletionBlock)completion
                   progress:(CPABootstrapProgressBlock)progress
{
    return [self setupWithCompletion:completion progress:progress callbackQueue:NULL];
}

- (void)setupWithCompletion:(CPABootstrapCompletionBlock)completion
                   progress:(CPABootstrapProgressBlock)progress
              callbackQueue:(dispatch_queue_t)completionQueue
{
    if (self.controlPortStatus != CPAControlPortStatusClosed) {
        return;
    }
    self.controlPortStatus = CPAControlPortStatusConnecting;
    self.status = CPAStatusConnecting;
    
    self.completionBlock = completion;
    self.progressBlock = progress;
    self.callbackQueue = completionQueue;
    if (!self.callbackQueue) {
        self.callbackQueue = dispatch_get_main_queue();
    }
    
    if (self.configuration.torrcPath == nil
        || self.configuration.geoipPath == nil) {
        
        NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Torrc or geoip path not set." };
        NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorTorrcOrGeoipPathNotSet userInfo:userInfo];
        [self failWithError:error];
        return;
    }
    
    // Only start the tor thread if it's not already executing
    if (!self.torThread.isExecuting) {
        [self.torThread start];
    }
    
    [self postNotificationWithName:CPAProxyDidStartSetupNotification];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:CPATimeoutDelay
                                                             target:self
                                                           selector:@selector(handleTimeout)
                                                           userInfo:nil
                                                            repeats:NO];
    });
    
    
    // This is a pretty ungly hack but it will have to do for the moment.
    // Wait for a constant amount of time after starting the main Tor client before opening a socket
    // and send an authentication message.
    [self performSelector:@selector(connectSocket) withObject:nil afterDelay:CPAConnectToTorSocketDelay];
}

- (void)connectSocket
{
    if (self.controlPortStatus != CPAControlPortStatusConnecting) {
        return;
    }
        
    [self.socketManager connectToHost:self.configuration.socksHost port:self.configuration.controlPort error:nil];
}

#pragma mark - CPASocketManagerDelegate methods

- (void)socketManager:(CPASocketManager *)manager didReceiveResponse:(NSString *)response forCommand:(CPAProxyCommand *)command
{
    if (command.responseBlock) {
        dispatch_queue_t queue = dispatch_get_main_queue();
        if (command.responseQueue) {
            queue = command.responseQueue;
        }
        dispatch_async(queue, ^{
            command.responseBlock(response,nil);
        });
    }
    
    if ([CPAProxyResponseParser responseTypeForResponse:response] == CPAResponseTypeAsynchronous) {
        [self handleAsyncReponse:response];
    }
}

- (void)socketManagerDidOpenSocket:(CPASocketManager *)manager
{
    if(self.controlPortStatus == CPAStatusConnecting) {
        [self cpa_sendAuthenticateWithCompletion:^(NSString *responseString, NSError *error) {
            [self handleInitialAuthenticateResponse:responseString];
        } completionQueue:self.workQueue];
        [self cpa_setEvents:@[kCPAProxyEventStatusClient] extended:NO completion:^(NSString *responseString, NSError *error) {
            NSLog(@"%@",responseString);
        } completionQueue:self.workQueue];
    }
}

- (void)socketManagerDidFailToOpenSocket:(CPASocketManager *)manager
{
    self.controlPortStatus = CPAControlPortStatusClosed;
    
    NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Failed to connect to socket" };
    NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorSocketOpenFailed userInfo:userInfo];
    [self failWithError:error];
}

#pragma mark - Handle Tor control responses

- (void)handleAsyncReponse:(NSString *)response
{
    if ([response rangeOfString:kCPAProxyEventStatusClient].location != NSNotFound) {
        [self handleStatusClientAsyncResponse:response];
    }
}

- (void)handleStatusClientAsyncResponse:(NSString *)response
{
    if ([response rangeOfString:@"BOOTSTRAP"].location != NSNotFound) {
        [self handleInitialBootstrapProgressResponse:response];
    }
}

- (void)handleInitialAuthenticateResponse:(NSString *)response
{
    CPAResponseType responseType = [CPAProxyResponseParser responseTypeForResponse:response];
    
    if (responseType == CPAResponseTypeSuccess) {
        
        self.controlPortStatus = CPAControlPortStatusAuthenticated;
        
    } else {
        NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Failed to authenticate to Tor. The control_auth_cookie in Tor's temporary directory may contain a wrong value." };
        NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorTorAuthenticationFailed userInfo:userInfo];
        
        [self failWithError:error];
    }
}

- (void)handleInitialBootstrapProgressResponse:(NSString *)response
{
    NSInteger progress = [CPAProxyResponseParser bootstrapProgressForResponse:response];
    
    if (self.progressBlock) {
        NSString *summaryString = [CPAProxyResponseParser bootstrapSummaryForResponse:response];
        __weak typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.progressBlock(progress,summaryString);
        });
        
    }

    if (progress == CPABootstrapProgressPercentageDone) {
        
        self.status = CPAStatusOpen;
        
        [self.bootstrapTimer invalidate];
        [self.timeoutTimer invalidate];
        
        [self postNotificationWithName:CPAProxyDidFinishSetupNotification];
        
        NSString *socksHost = self.configuration.socksHost;
        NSUInteger socksPort = self.configuration.socksPort;
        if (self.completionBlock) {
            __weak typeof(self)weakSelf = self;
            dispatch_async(self.callbackQueue, ^{
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.completionBlock(socksHost, socksPort, nil);
            });
            
        }
    }
}

#pragma mark - Utilities

- (void)postNotificationWithName:(NSString * const)notificationName
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:weakSelf];
    });
}

- (void)failWithError:(NSError *)error
{
    [self.timeoutTimer invalidate];
    [self.bootstrapTimer invalidate];
    
    [self postNotificationWithName:CPAProxyDidFailSetupNotification];
    
    if (self.completionBlock) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            strongSelf.completionBlock(nil,0,error);
        });
        
    }
}

- (void)handleTimeout
{
    NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Tor setup did timeout." };
    NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorTorSetupTimedOut userInfo:userInfo];
    [self failWithError:error];
}

- (NSString *)SOCKSHost
{
    return self.configuration.socksHost;
}

- (NSUInteger)SOCKSPort
{
    return self.configuration.socksPort;
}

+ (NSString *) opensslVersion
{
    return [NSString stringWithUTF8String:SSLeay_version(0)];
}

+ (NSString *) libeventVersion
{
    return [NSString stringWithUTF8String:event_get_version()];
}

+ (NSString *) torVersion
{
    return [NSString stringWithUTF8String:get_version()];
}

@end
