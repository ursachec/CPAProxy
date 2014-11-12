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
    return [self initWithCommandString:commandString tag:nil responseBlock:nil];
}

- (instancetype)initWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    return [self initWithCommandString:commandString tag:tag responseBlock:responseBlock responseQueue:nil];
    
}

- (instancetype)initWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
                        responseQueue:(dispatch_queue_t)responseQueue
{
    if (self = [self init]) {
        self.commandString = commandString;
        self.tag = tag;
        self.responseBlock = responseBlock;
        self.responseQueue = responseQueue;
    }
    return self;
}


+ (instancetype)commandWithCommandString:(NSString *)commandString
{
    return [self commandWithCommandString:commandString tag:nil responseBlock:nil];
}

+ (instancetype)commandWithCommandString:(NSString *)commandString
                                     tag:(id)tag
                           responseBlock:(CPAProxyCommandResponseBlock)responseBlock
{
    return [self commandWithCommandString:commandString tag:tag responseBlock:responseBlock responseQueue:nil];
}

+ (instancetype)commandWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
                        responseQueue:(dispatch_queue_t)responseQueue
{
    return [[self alloc] initWithCommandString:commandString tag:tag responseBlock:responseBlock responseQueue:responseQueue];
}

@end
