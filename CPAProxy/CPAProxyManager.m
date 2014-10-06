//  CPAProxyManager.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAProxyManager.h"
#import "CPAThread.h"
#import "CPAConfiguration.h"
#import "CPAProxyManager+TorCommands.h"
#import "CPASocketManager.h"

NSString * const CPAProxyDidStartSetupNotification = @"com.cpaproxy.setup.start";
NSString * const CPAProxyDidFailSetupNotification = @"com.cpaproxy.setup.fail";
NSString * const CPAProxyDidFinishSetupNotification = @"com.cpaproxy.setup.finish";

NSString * const CPAErrorDomain = @"CPAErrorDomain";

const NSTimeInterval CPAConnectToTorSocketDelay = 0.5;
const NSTimeInterval CPAGetBoostrapProgressInterval = 2.0;
const NSTimeInterval CPATimeoutDelay = 25;

const NSInteger CPABoostrapProgressPercentageDone = 100;

typedef NS_ENUM(NSUInteger, CPAErrors) {
    CPAErrorTorrcOrGeoipPathNotSet = 0,
    CPAErrorTorAuthenticationFailed,
    CPAErrorSocketOpenFailed,
    CPAErrorTorSetupTimedOut,
};

typedef NS_ENUM(NSUInteger, CPAStatus) {
    CPAStatusClosed = 0,
    CPAStatusConnecting,
    CPAStatusAuthenticated,
    CPAStatusBootstrapDone,
    CPAStatusOpen
};

@interface CPAProxyManager () <CPASocketManagerDelegate>
@property (nonatomic, strong, readwrite) CPASocketManager *socketManager;
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@property (nonatomic, strong, readwrite) CPAThread *torThread;

@property (nonatomic, strong, readwrite) NSTimer *boostrapTimer;
@property (nonatomic, strong, readwrite) NSTimer *timeoutTimer;
@property (nonatomic, copy, readwrite) CPABootstrapCompletionBlock completionBlock;
@property (nonatomic, copy, readwrite) CPABootstrapProgressBlock progressBlock;

@property (nonatomic, readwrite) CPAStatus status;
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
    
    self.status = CPAStatusClosed;
    
    self.configuration = configuration;
    self.torThread = torThread;
    
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
    if (self.status != CPAStatusClosed) {
        return;
    }
    self.status = CPAStatusConnecting;
    
    self.completionBlock = completion;
    self.progressBlock = progress;
    
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
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:CPATimeoutDelay
                                                          target:self
                                                        selector:@selector(handleTimeout)
                                                        userInfo:nil
                                                         repeats:NO];
    
    // This is a pretty ungly hack but it will have to do for the moment.
    // Wait for a constant amount of time after starting the main Tor client before opening a socket
    // and send an authentication message.
    [self performSelector:@selector(connectSocket) withObject:nil afterDelay:CPAConnectToTorSocketDelay];
}

- (void)connectSocket
{
    if (self.status != CPAStatusConnecting) {
        return;
    }
        
    [self.socketManager connectToHost:self.configuration.socksHost port:self.configuration.controlPort];
}

#pragma mark - CPASocketManagerDelegate methods

- (void)socketManager:(CPASocketManager *)manager didReceiveResponse:(NSString *)response
{
    if(self.status == CPAStatusConnecting) {
        [self handleInitialAuthenticateResponse:response];
    } else if(self.status == CPAStatusAuthenticated) {
        [self handleInitialBoostrapProgressResponse:response];
    }
}

- (void)socketManagerDidOpenSocket:(CPASocketManager *)manager
{
    if(self.status == CPAStatusConnecting) {
        [self cpa_sendAuthenticate];
    }
}

- (void)socketManagerDidFailToOpenSocket:(CPASocketManager *)manager
{        
    NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Failed to connect to socket" };
    NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorSocketOpenFailed userInfo:userInfo];
    [self failWithError:error];
}

#pragma mark - Handle Tor control responses

- (void)handleInitialAuthenticateResponse:(NSString *)response
{
    BOOL authenticated = [self cpa_isAuthenticatedForResponse:response];
    
    if (authenticated) {
        
        self.status = CPAStatusAuthenticated;
        
        // Ask for the boostrap progress until it's done
        SEL boostrapInfoSel = @selector(cpa_sendGetBoostrapInfo);
        self.boostrapTimer = [NSTimer scheduledTimerWithTimeInterval:CPAGetBoostrapProgressInterval
                                                              target:self
                                                            selector:boostrapInfoSel
                                                            userInfo:nil
                                                             repeats:YES];
    } else {
        NSDictionary *userInfo = @{ NSLocalizedFailureReasonErrorKey: @"Failed to authenticate to Tor. The control_auth_cookie in Tor's temporary directory may contain a wrong value." };
        NSError *error = [[NSError alloc] initWithDomain:CPAErrorDomain code:CPAErrorTorAuthenticationFailed userInfo:userInfo];
        
        [self failWithError:error];
    }
}

- (void)handleInitialBoostrapProgressResponse:(NSString *)response
{
    NSInteger progress = [self cpa_boostrapProgressForResponse:response];
    
    if (self.progressBlock) {
        NSString *summaryString = [self cpa_boostrapSummaryForResponse:response];
        self.progressBlock(progress,summaryString);
    }

    if (progress == CPABoostrapProgressPercentageDone) {
        
        self.status = CPAStatusBootstrapDone;
        
        [self.boostrapTimer invalidate];
        [self.timeoutTimer invalidate];
        
        [self postNotificationWithName:CPAProxyDidFinishSetupNotification];
        
        NSString *socksHost = self.configuration.socksHost;
        NSUInteger socksPort = self.configuration.socksPort;
        if (self.completionBlock) {
            self.completionBlock(socksHost, socksPort, nil);
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
    
    [self postNotificationWithName:CPAProxyDidFailSetupNotification];
    
    if (self.completionBlock) {
        self.completionBlock(nil,0,error);
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

@end
