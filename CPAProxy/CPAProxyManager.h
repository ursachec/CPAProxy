//  CPAProxyManager.h
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import <Foundation/Foundation.h>

@class CPAConfiguration;
@class CPASocketManager;
@class CPAThread;

typedef void (^CPABootstrapCompletionBlock)(NSString *socksHost, NSUInteger socksPort, NSError *error);
typedef void (^CPABootstrapProgressBlock)(NSInteger progress, NSString *summaryString);

//Tor connnection states
typedef NS_ENUM(NSUInteger, CPAStatus) {
    CPAStatusClosed = 0,
    CPAStatusConnecting,
    CPAStatusOpen
};

/**
 `CPAProxyManager` is a class responsible for coordinating the creation and communication with a Tor client running in a separate thread represented by `CPAThread`. After the Tor client has been started using the `CPAThread` instance, the `CPAProxyManager` uses `CPASocketManager` to send control messages until it has successfully bootstrapped Tor.
 
 Right after starting Tor, the control message "AUTHENTICATE %control_auth_cookie%" is sent. This uses data from a auth cookie created in Tor's temp directory specified by `CPAConfiguration`.
 
 If the authentication has succeeded, the `CPAProxyManager` starts sending "GETINFO status/bootstrap-phase" messages to poll for the bootstrap progress of the Tor client. When the response "BOOTSTRAP PROGRESS=100" has been received, the client is considered to have been successfully setup and the SOCKS proxy is ready to be used.
 */

@interface CPAProxyManager : NSObject

/**
 The thread used for wrapping the Tor client.
 */
@property (nonatomic, strong, readonly) CPAThread *torThread;

/**
 The configuration object being used by this instance of `CPAProxyManager`. This is usually set at initialization.
 */
@property (nonatomic, strong, readonly) CPAConfiguration *configuration;

/**
 Returns bootstrap connection status of Tor
 */
@property (nonatomic, readonly) CPAStatus status;

/**
 *  Returns whether or not CPAProxyManager thinks Tor is fully connected.
 *  Shortcut for status == CPAStatusOpen
 */
@property (nonatomic, readonly) BOOL isConnected;

/**
 Convenience method that returns the configuration's SOCKS host
 */
@property (nonatomic, readonly) NSString *SOCKSHost;

/**
 Convenience method that returns the configuration's SOCKS port
 */
@property (nonatomic, readonly) NSUInteger SOCKSPort;

/**
 The socket manager that writes and reads data from the Tor client's control port.
 */
@property (nonatomic, strong, readonly) CPASocketManager *socketManager;

/**
 Creates and returns an instance of `CPAProxyManager` with the specified configuration.
 
 @param configuration The configuration object for the `CPAProxyManager`.
 */
+ (instancetype)proxyWithConfiguration:(CPAConfiguration *)configuration;

/**
 Initializes a `CPAProxyManager` with the specified configuration.
 
 @param configuration The configuration object for the `CPAProxyManager`.
 @return A newly initialized `CPAProxyManager`
 */
- (instancetype)initWithConfiguration:(CPAConfiguration *)configuration;

/**
 Starts running the `CPAThread` wrapping a Tor client, sends authentication and `get bootstrap info` messages to the control port and runs the success block with the SOCKS proxy's host and port on success. If anything goes wrong, the failure block is called with an NSError with `CPAErrorDomain`.
 
 @param success The success block containing the hostname and port of the usable Tor SOCKS proxy.
 @param failure The failure block containing an error describing what went wrong.
 */
- (void)setupWithCompletion:(CPABootstrapCompletionBlock)completion
                   progress:(CPABootstrapProgressBlock)progress;

/**
 Starts running the `CPAThread` wrapping a Tor client, sends authentication and `get bootstrap info` messages to the control port and runs the success block with the SOCKS proxy's host and port on success. If anything goes wrong, the failure block is called with an NSError with `CPAErrorDomain`.
 
 @param success The success block containing the hostname and port of the usable Tor SOCKS proxy.
 @param failure The failure block containing an error describing what went wrong.
 @param callbackQueue The Queue on which the blocks will be called on, defaults to main queue
 */
- (void)setupWithCompletion:(CPABootstrapCompletionBlock)completion
                   progress:(CPABootstrapProgressBlock)progress
              callbackQueue:(dispatch_queue_t)callbackQueue;

/**
 @return Current version string for OpenSSL https://www.openssl.org
 */
+ (NSString*) opensslVersion;

/**
 @return Current version string for Tor https://www.torproject.org
 */
+ (NSString*) torVersion;

/**
 @return Current version string for Libevent http://libevent.org
 */
+ (NSString*) libeventVersion;

@end

/**
 Ceppa error domain.
 */
extern NSString * const CPAErrorDomain;

/**
 Notification posted when a CPAProxy begins setting up.
 */
extern NSString * const CPAProxyDidStartSetupNotification;

/**
 Notification posted when a CPAProxy fails setting up.
 */
extern NSString * const CPAProxyDidFailSetupNotification;

/**
 Notification posted when a CPAProxy successfully finished setting up.
 */
extern NSString * const CPAProxyDidFinishSetupNotification;
