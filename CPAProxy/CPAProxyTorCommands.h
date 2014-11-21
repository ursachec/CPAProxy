//
//  CPAProxyCommands.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

/**
 * For more information see: https://gitweb.torproject.org/torspec.git/blob/HEAD:/control-spec.txt
 */
@interface CPAProxyTorCommands : NSObject

/**
 *  AUTHENTICATE command wrapper
 */
+ (NSString *)authenticateCommandWithCookieHexString:(NSString *)hexString;

/**
 *  SIGNAL command wrapper
 */
+ (NSString *)sendSignalCommandWithKeyword:(NSString *)keyword;

/**
 *  GETCONF command wrapper
 */
+ (NSString *)getConfigurationCommandWithKeyword:(NSString *)keyword;

/**
 *  GETINFO command wrapper
 */
+ (NSString *)getInfoCommandWithKeyword:(NSString *)keyword;

/**
 *  SETEVENTS command wrapper
 */
+ (NSString *)setEventsCommandWithEventsArray:(NSArray *)events extended:(BOOL)extended;

@end
