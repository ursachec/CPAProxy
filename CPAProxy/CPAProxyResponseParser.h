//
//  CPAProxyParser.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CPAResonpseType) {
    CPAResonpseTypeUnkown,
    CPAResonpseTypeSucess,
    CPAResonpseTypeTemporaryNegative,
    CPAResonpseTypePermanentNegative,
    CPAResonpseTypeAsynchronous
};

@interface CPAProxyResponseParser : NSObject

/**
 Parses a response and returns the status code. 
 Status codes can be found in the Tor control protocol 4. Replies.
 
 @param response The response from the tor control port
 @return The status code
 **/
+ (NSInteger)statusCodeForResponse:(NSString *)response;

/**
 Parses a response and returns the CPAResonpseType.
 
 @param response The response from the tor control port
 @return The response type
 **/
+ (CPAResonpseType)responseTypeForResponse:(NSString *)response;

/**
 Parses a `get boostrap info` response and returns the percentage completed.
 
 @param response The response to an `get boostrap info` message.
 @return An integer between 0 and 100 representing the boostrap progress of the Tor client.
 **/
+ (NSInteger)boostrapProgressForResponse:(NSString *)response;

/**
 Parses a `get boostrap info` response and returns the summary string.
 
 @param response The response to an `get boostrap info` message.
 @return A string representing the boostrap summary of the Tor client.
 **/
+ (NSString *)boostrapSummaryForResponse:(NSString *)response;

@end
