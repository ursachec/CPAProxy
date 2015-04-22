//  CPASocketManager.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPASocketManager.h"

#import "GCDAsyncSocket+CPAProxy.h"
#import "CPAProxyCommand.h"
#import "CPAProxyTorCommandConstants.h"
#import "CPAProxyResponseParser.h"

const NSTimeInterval CPASocketTimeoutDelay = 3;
const NSTimeInterval CPASocketReadTimeout = -1;
const long CPASocketDidConnectReadTag = 101;
const long CPASocketDidReadReadTag = 102;
const long CPASocketDidWriteReadTag = 102;
const long CPASocketWriteTag = 110;

@interface CPASocketManager () <GCDAsyncSocketDelegate>

@property (nonatomic, weak, readwrite) id<CPASocketManagerDelegate> delegate;
@property (nonatomic, readwrite) BOOL isConnected;
@property (nonatomic, strong, readwrite) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableArray *waitingCommands;
@property (nonatomic) dispatch_queue_t socketQueue;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic) dispatch_queue_t isolationQueue;
@property (nonatomic) dispatch_queue_t workQueue;

@property (nonatomic, strong) NSMutableString *multiLineResponseString;

@end

@implementation CPASocketManager

- (instancetype)initWithDelegate:(id<CPASocketManagerDelegate>)delegate
{
    return [self initWithDelegate:delegate delegateQueue:NULL];
}

- (instancetype)initWithDelegate:(id<CPASocketManagerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue
{
    return [self initWithDelegate:delegate delegateQueue:delegateQueue socketQueue:NULL];
}

- (instancetype)initWithDelegate:(id<CPASocketManagerDelegate>)delegate delegateQueue:(dispatch_queue_t)delegateQueue socketQueue:(dispatch_queue_t)socketQueue
{
    if(self = [super init]) {
        
        if(!delegateQueue) {
            delegateQueue = dispatch_get_main_queue();
        }
        
        self.delegateQueue = delegateQueue;
        
        NSString *isolationLabel = [NSString stringWithFormat:@"%@.isolation.%p", [self class], self];
        self.isolationQueue = dispatch_queue_create([isolationLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
        
        NSString *workLabel = [NSString stringWithFormat:@"%@.work.%p", [self class], self];
        self.workQueue = dispatch_queue_create([workLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        
        self.waitingCommands = [NSMutableArray new];
        
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                 delegateQueue:dispatch_queue_create([@"GCDAsyncSocket-delegate" UTF8String], NULL)
                                                   socketQueue:socketQueue];
        self.delegate = delegate;
    }
    
    return self;
}

#pragma - mark waitingList Isolation

- (void)addWaitingCommandToList:(CPAProxyCommand *)command
{
    if (command) {
        dispatch_barrier_async(self.isolationQueue, ^{
            [self.waitingCommands addObject:command];
        });
    }
}

- (CPAProxyCommand *)commandAtIndex:(NSUInteger)index
{
    __block CPAProxyCommand *command = nil;
    dispatch_sync(self.isolationQueue, ^{
        if(index < [self.waitingCommands count]) {
            command = self.waitingCommands[index];
        }
    });
    return command;
}

- (void)removeCommandAtIndex:(NSUInteger)index
{
    dispatch_barrier_async(self.isolationQueue, ^{
        if (index < [self.waitingCommands count]) {
            [self.waitingCommands removeObjectAtIndex:index];
        }
    });
}

 #pragma - mark Public Methods

- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;
{
    [self.socket connectToHost:host onPort:port error:error];
}

- (void)sendCommand:(CPAProxyCommand *)command
{
    if([command.commandString length]) {
        [self addWaitingCommandToList:command];
        [self writeString:command.commandString encoding:NSUTF8StringEncoding];
    }
}

- (void)writeString:(NSString *)string encoding:(NSStringEncoding)encoding
{
    [self.socket cpa_writeString:string withEncoding:encoding timeout:CPASocketTimeoutDelay tag:CPASocketWriteTag];
    [self.socket readDataWithTimeout:CPASocketReadTimeout tag:CPASocketDidWriteReadTag];
}

#pragma - mark handle socket

- (void)handleSocketConnected
{
    self.isConnected = YES;
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.delegateQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.delegate socketManagerDidOpenSocket:strongSelf];
    });
}

- (void)handleSocketDisconnectedWithError:(NSError *)error
{
    self.isConnected = NO;
    
    if ([self.delegate respondsToSelector:@selector(socketManager:didDisconnectError:)]) {
        __weak typeof(self)weakSelf = self;
        dispatch_async(self.delegateQueue, ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            [self.delegate socketManager:strongSelf didDisconnectError:error];
        });
    }
}

/**
 Responses in this case should have all CRLF removed.
 Responses should have exactly one status code.
 **/
- (void)handleResponse:(NSString *)response
{
    CPAResponseType responseType = [CPAProxyResponseParser responseTypeForResponse:response];
    CPAProxyCommand *command = nil;
    
    if (responseType != CPAResponseTypeAsynchronous || responseType != CPAResponseTypeUnknown) {
        command = [self commandAtIndex:0];
        [self removeCommandAtIndex:0];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.delegateQueue, ^{
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.delegate socketManager:strongSelf didReceiveResponse:response forCommand:command];
    });
}

- (void)handleSocketLineString:(NSString *)lineString
{
    if (![lineString length]) {
        return;
    }
    
    /**
     '.' denotes end of multiline response so the mutable string we've built is completed.
     Otherwise if there is a mutable string being built keep on adding to it.
     If The string length is greater than 3 and the 4th character is '+' that means it is the start of a multiline response (may need to check for status numbers in the beginning).
     Otherwise normal one line response
     **/
    if ([lineString isEqualToString:@"."] && [self.multiLineResponseString length]) {
        [self handleResponse:[self.multiLineResponseString copy]];
        self.multiLineResponseString = nil;
    }
    else if ([self.multiLineResponseString length]) {
        [self.multiLineResponseString appendFormat:@"\n%@",lineString];
    }
    else if ([lineString length] > 3 && [[lineString substringWithRange:NSMakeRange(3, 1)] isEqualToString:@"+"]) {
        self.multiLineResponseString = [lineString mutableCopy];
    }
    else {
        [self handleResponse:lineString];
    }
}

- (void)handleSocketDataAsString:(NSString *)string
{
    /**
     If string contains CRLF then break it up into indpendent lines
     **/
    if ([string rangeOfString:kCPAProxyCRLF].location != NSNotFound) {
        NSArray *components = [string componentsSeparatedByString:kCPAProxyCRLF];
        
        [components enumerateObjectsUsingBlock:^(NSString *lineString, NSUInteger idx, BOOL *stop) {
            
            [self handleSocketLineString:lineString];
        }];
    } else {
        [self handleSocketLineString:string];
    }
}

#pragma - mark GCDAsyncSocketDelegate Methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [self handleSocketConnected];
    [self.socket readDataWithTimeout:CPASocketReadTimeout tag:CPASocketDidConnectReadTag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [self handleSocketDisconnectedWithError:err];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    dispatch_async(self.workQueue, ^{
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self handleSocketDataAsString:response];
    });
    [self.socket readDataWithTimeout:CPASocketReadTimeout tag:CPASocketDidReadReadTag];
}

@end
