//
//  CPAProxyCommands.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

@interface CPAProxyTorCommands : NSObject

+ (NSString *)authenticateCommandWithCookieHexString:(NSString *)hexString;

+ (NSString *)getInfoCommandWithKeyword:(NSString *)keyword;

+ (NSString *)setEventsCommandWithEventsArray:(NSArray *)events extended:(BOOL)extended;

@end
