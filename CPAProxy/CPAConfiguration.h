//  CPAConfiguration.h
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import <Foundation/Foundation.h>

/**
`CPAConfiguration` handles data used used by `CPAThread` and `CPAProxyManager`. It provides information like the temporary directory to be used for storing the Tor clients's data, control port, SOCKS port and paths to torrc and geoip.
 
*/

@interface CPAConfiguration : NSObject

/**
 Creates and returns a `CPAConfiguration` with the specified torrc and geoip paths.
 
 @param Path to a torrc file.
 @param Path to a geoip file.
 @param Path to directory to be used as teh tor data directory if set to nil then a directory is created in the system temporary directory
 @return A newly initialized `CPAConfiguration`.
 */
+ (instancetype)configurationWithTorrcPath:(NSString *)torrcPath
                                 geoipPath:(NSString *)geoipPath
                      torDataDirectoryPath:(NSString *)torDataDirectoryPath;

/**
 Initializes a `CPAConfiguration` with the specified torrc and geoip paths.
 
 @param torrcPath Path to a torrc file.
 @param geoipPath Path to a geoip file.
 @param Path to directory to be used as teh tor data directory if set to nil then a directory is created in the system temporary directory
 @return A newly initialized `CPAConfiguration`.
 */
- (instancetype)initWithTorrcPath:(NSString *)torrcPath
                        geoipPath:(NSString *)geoipPath
             torDataDirectoryPath:(NSString *)torDataDirectoryPath;

/**
 The port for the Tor SOCKS proxy.
 */
@property (nonatomic, readonly) uint16_t socksPort;

/** If set, socksPort will be 9050 */
@property (nonatomic) BOOL useDefaultSocksPort;

/**
 The hostname for the Tor SOCKS proxy.
 */
@property (nonatomic, copy, readonly) NSString *socksHost;

/**
 The control port used by a Tor client.
 */
@property (nonatomic, readonly) uint16_t controlPort;

/**
 Returns the control auth cookie saved by the Tor client on startup. If the Tor client has not been started, this will be nil.
 */
@property (nonatomic, strong, readonly) NSData *torCookieData;

/**
 Returns the Tor control auth cookie as hex.
 */
@property (nonatomic, copy, readonly) NSString *torCookieDataAsHex;

/**
 Returns the path to the Tor data directory.
 */
@property (nonatomic, copy, readonly) NSString *torDataDirectoryPath;

/**
 Returns the path to the torrc file.
 */
@property (nonatomic, copy, readwrite) NSString *torrcPath;

/**
 Returns the path to the geoip file.
 */
@property (nonatomic, copy, readwrite) NSString *geoipPath;

/**
 *  Don’t share circuits with streams targetting a different destination port.
 *  See IsolateDestPort in https://www.torproject.org/docs/tor-manual.html.en for more details.
 *  Defaults to NO.
 */
@property (nonatomic, readwrite) BOOL isolateDestinationPort;

/**
 *  Don’t share circuits with streams targetting a different destination address.
 *  See IsolateDestAddr in https://www.torproject.org/docs/tor-manual.html.en for more details.
 *  Defaults to NO.
 */
@property (nonatomic, readwrite) BOOL isolateDestinationAddress;

@end
