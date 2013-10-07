//  CPASocketManager.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPASocketManager.h"

#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <unistd.h>

const NSTimeInterval CPASocketTimeoutDelay = 3.0f;

@interface CPASocketManager ()
@property (nonatomic, readwrite) CFSocketRef socketRef;
@property (nonatomic, strong, readwrite) NSTimer *timeoutTimer;
@property (nonatomic, weak, readwrite) id<CPASocketManagerDelegate> delegate;
@property (nonatomic, readwrite) BOOL isConnected;
@end

@implementation CPASocketManager

- (instancetype)initWithDelegate:(id<CPASocketManagerDelegate>)delegate
{
    self = [super init];
    if(!self) return nil;
    
    self.delegate = delegate;
    
    return self;
}

- (void)dealloc
{
    CFSocketInvalidate(self.socketRef);
    CFRelease(self.socketRef);
    self.socketRef = NULL;
}

- (void)connectToHost:(NSString *)host port:(NSUInteger)port
{
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:CPASocketTimeoutDelay
                                                         target:self 
                                                       selector:@selector(handleSocketTimeout) 
                                                       userInfo:self 
                                                        repeats:NO];
    
    self.socketRef = [self socketRefWithHost:host port:port];
}

- (void)writeString:(NSString *)string encoding:(NSStringEncoding)encoding
{
    if (nil == self.socketRef) {
        return;
    }
    
    NSData *data = [string dataUsingEncoding:encoding];    
    CFSocketError serr = CFSocketSendData(self.socketRef, NULL, (__bridge CFDataRef)data, 0);
    if (serr == kCFSocketError) {
        return;
    }
}

- (void)handleSocketTimeout
{
    if ([self.delegate respondsToSelector:@selector(socketManagerDidFailToOpenSocket:)]) {
        [self.delegate socketManagerDidFailToOpenSocket:self];
    }
}

- (void)handleSocketConnected
{
    self.isConnected = YES;
}

- (void)handleSocketWritable
{
    CFSocketDisableCallBacks(self.socketRef, kCFSocketWriteCallBack);
    
    [self.timeoutTimer invalidate];
    
    if ([self.delegate respondsToSelector:@selector(socketManagerDidOpenSocket:)]) {
        [self.delegate socketManagerDidOpenSocket:self];
    }
}

- (void)handleSocketDataAsString:(NSString *)string
{
    if ([self.delegate respondsToSelector:@selector(socketManager:didReceiveResponse:)]) {
        [self.delegate performSelector:@selector(socketManager:didReceiveResponse:) withObject:self withObject:string];
    }
}

- (void)handleSocketData:(const void *)data
{
    CFIndex nBytes = CFDataGetLength(data);
    if (nBytes <= 0) {
        return;
    }
    
    UInt8 *buffer = malloc(nBytes);
    CFDataRef dataRef = (CFDataRef) data;
    CFDataGetBytes(dataRef, CFRangeMake(0, nBytes), buffer);
    
    NSString *s = [[NSString alloc] initWithBytes:buffer length:nBytes encoding:NSASCIIStringEncoding];
    [self handleSocketDataAsString:s];
    
    free(buffer);
}

- (CFSocketRef)socketRefWithHost:(NSString *)host port:(NSUInteger)port
{    
    // Retrieve host information
    const char *hostName = [host UTF8String];
	struct hostent *socketHost = gethostbyname(hostName);
	if( !socketHost ) {
		return nil;
    }
    
    // Create native socket and set additional flags
    CFSocketNativeHandle nativeSocket = socket(AF_INET, SOCK_STREAM, 0);
    
    // Create the socket context and include self as info
    CFSocketContext context;
    bzero(&context, sizeof(context));
	context.info = (__bridge void *)(self);
    
    // Create the socket ref and set callback flags
    CFOptionFlags callbackFlags = (kCFSocketConnectCallBack|kCFSocketWriteCallBack|kCFSocketDataCallBack);
    CFSocketRef sRef = CFSocketCreateWithNative(NULL, nativeSocket, callbackFlags, &cpa_socketCallback, &context);
    CFSocketSetSocketFlags(sRef, kCFSocketAutomaticallyReenableReadCallBack);
    
    // Setup socket address
    struct sockaddr_in saddr;
	bzero(&saddr, sizeof(saddr));
	bcopy((char *)socketHost->h_addr, (char *)&saddr.sin_addr, socketHost->h_length);
	saddr.sin_family = PF_INET;
	saddr.sin_port = htons(port);
    saddr.sin_len = sizeof(saddr);
    
    // Connect the socket
    NSData *saddrData = [NSData dataWithBytes:&saddr length:sizeof(saddr)];
    CFSocketError socketError = CFSocketConnectToAddress(sRef, (__bridge CFDataRef) saddrData, -1);
    if( socketError != kCFSocketSuccess ) {
		return nil;
	}
    
    // Add the runloop source to the socket
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(NULL, sRef, 1);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    CFRelease(source);	
    
    return sRef;
}

void cpa_socketCallback(CFSocketRef s, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
	CPASocketManager *manager = (__bridge CPASocketManager *)info;
	if( !manager ) {
		return;
    }
	
	switch( callbackType ) {
        case kCFSocketConnectCallBack:
            [manager handleSocketConnected];
            break;
        case kCFSocketDataCallBack: {
            [manager handleSocketData:data];
        } break;
            
		case kCFSocketWriteCallBack: {
            [manager handleSocketWritable];
        } break;
            
		default:
			break;
	}
}

@end
