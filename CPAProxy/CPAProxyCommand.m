//
//  CPAProxyCommand.m
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import "CPAProxyCommand.h"

@implementation CPAProxyCommand

- (instancetype)initWithCommandString:(NSString *)commandString
{
    return [self initWithCommandString:commandString responseBlock:nil];
}

- (instancetype)initWithCommandString:(NSString *)commandString
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    return [self initWithCommandString:commandString tag:nil responseBlock:responseBlock];
}

- (instancetype)initWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    if (self = [self init]) {
        self.commandString = commandString;
        self.tag = tag;
        self.responseBlock = responseBlock;
    }
    return self;
}


+ (instancetype)commandWithCommandString:(NSString *)commandString
{
    return [self commandWithCommandString:commandString responseBlock:nil];
}

+ (instancetype)commandWithCommandString:(NSString *)commandString
                           responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    return [self commandWithCommandString:commandString tag:nil responseBlock:responseBlock];
}

+ (instancetype)commandWithCommandString:(NSString *)commandString
                                     tag:(id)tag
                           responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    return [[self alloc] initWithCommandString:commandString tag:tag responseBlock:responseBlock];
}

@end
