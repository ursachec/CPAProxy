//
//  CPAProxyCommands.m
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import "CPAProxyTorCommands.h"
#import "CPAProxyTorCommandConstants.h"

@implementation CPAProxyTorCommands

+ (NSString *)authenticateCommandWithCookieHexString:(NSString *)hexString
{
    return [NSString stringWithFormat:@"AUTHENTICATE %@%@",hexString,kCPAProxyCRLF];
}

+ (NSString *)getConfigurationCommandWithKeyword:(NSString *)keyword {
    return [NSString stringWithFormat:@"GETCONF %@%@",keyword,kCPAProxyCRLF];
}

/**
 *  SIGNAL command wrapper
 */
+ (NSString *)sendSignalCommandWithKeyword:(NSString *)keyword {
    return [NSString stringWithFormat:@"SIGNAL %@%@",keyword,kCPAProxyCRLF];
}

+ (NSString *)getInfoCommandWithKeyword:(NSString *)keyword
{
    return [NSString stringWithFormat:@"GETINFO %@%@",keyword,kCPAProxyCRLF];
}

+ (NSString *)setEventsCommandWithEventsArray:(NSArray *)events extended:(BOOL)extended
{
    NSMutableString *command = [NSMutableString stringWithFormat:@"SETEVENTS"];
    if ([events count]) {
        if (extended) {
            [command appendString:@" EXTENDED"];
        }
        
        [events enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                [command appendString:[NSString stringWithFormat:@" %@",obj]];
            }
        }];
    }
    [command appendString:kCPAProxyCRLF];
    return command;
}

@end
