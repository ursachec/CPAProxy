//
//  CPAProxyCommand.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

typedef void (^CPAProxyCommandResponseBlock)(NSString *responseString, NSError *error);

@interface CPAProxyCommand : NSObject

@property (nonatomic, strong) NSString *commandString;
@property (nonatomic, strong) CPAProxyCommandResponseBlock responseBlock;
@property (nonatomic, strong) dispatch_queue_t responseQueue;
@property (nonatomic, strong) id tag;

- (instancetype)initWithCommandString:(NSString *)commandString;

- (instancetype)initWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock;

- (instancetype)initWithCommandString:(NSString *)commandString
                                  tag:(id)tag
                        responseBlock:(CPAProxyCommandResponseBlock)responseBlock
                        responseQueue:(dispatch_queue_t)responseQueue;


+ (instancetype)commandWithCommandString:(NSString *)commandString;

+ (instancetype)commandWithCommandString:(NSString *)commandString
                                     tag:(id)tag
                           responseBlock:(CPAProxyCommandResponseBlock)responseBlock;

+ (instancetype)commandWithCommandString:(NSString *)commandString
                                     tag:(id)tag
                           responseBlock:(CPAProxyCommandResponseBlock)responseBlock
                           responseQueue:(dispatch_queue_t)responseQueue;



@end
