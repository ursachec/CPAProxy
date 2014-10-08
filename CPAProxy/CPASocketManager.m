//  CPASocketManager.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPASocketManager.h"

#import "GCDAsyncSocket+CPAProxy.h"

const NSTimeInterval CPASocketTimeoutDelay = 3.0f;

@interface CPASocketManager () <GCDAsyncSocketDelegate>

@property (nonatomic, strong, readwrite) NSTimer *timeoutTimer;
@property (nonatomic, weak, readwrite) id<CPASocketManagerDelegate> delegate;
@property (nonatomic, readwrite) BOOL isConnected;
@property (nonatomic, strong, readwrite) GCDAsyncSocket *socket;
@property (nonatomic) dispatch_queue_t socketQueue;
@property (nonatomic) dispatch_queue_t delegateQueue;
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
        
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self
                                                 delegateQueue:dispatch_queue_create([@"GCDAsyncSocket-delegate" UTF8String], NULL)
                                                   socketQueue:socketQueue];
        self.delegate = delegate;
    }
    
    
    
    return self;
}

- (void)connectToHost:(NSString *)host port:(NSUInteger)port error:(NSError **)error;
{
    [self.socket connectToHost:host onPort:port error:error];
    
}

- (void)writeString:(NSString *)string encoding:(NSStringEncoding)encoding
{
    [self.socket cpa_writeString:string withEncoding:encoding timeout:CPASocketTimeoutDelay tag:0];
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)handleSocketTimeout
{
    if ([self.delegate respondsToSelector:@selector(socketManagerDidFailToOpenSocket:)]) {
        CPASocketManager *welf = self;
        dispatch_async(self.delegateQueue, ^{
            [welf.delegate socketManagerDidFailToOpenSocket:welf];
        });
    }
    
}

- (void)handleSocketConnected
{
    self.isConnected = YES;
}

- (void)handleSocketDataAsString:(NSString *)string
{
    if ([self.delegate respondsToSelector:@selector(socketManager:didReceiveResponse:)]) {
        CPASocketManager *welf = self;
        dispatch_async(self.delegateQueue, ^{
            [welf.delegate performSelector:@selector(socketManager:didReceiveResponse:) withObject:welf withObject:string];
        });
    }
    
}

#pragma - mark GCDAsyncSocketDelegate Methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    [self.timeoutTimer invalidate];
    [self handleSocketConnected];
    [self.socket readDataWithTimeout:-1 tag:0];
    
    if ([self.delegate respondsToSelector:@selector(socketManagerDidOpenSocket:)]) {
        CPASocketManager *welf = self;
        dispatch_async(self.delegateQueue, ^{
            [welf.delegate socketManagerDidOpenSocket:welf];
        });
    }
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    [self handleSocketDataAsString:response];
}

@end
