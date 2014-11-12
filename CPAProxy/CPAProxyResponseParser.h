//
//  CPAProxyParser.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CPAResponseType) {
    CPAResponseTypeUnknown,
    CPAResponseTypeSuccess,
    CPAResponseTypeTemporaryNegative,
    CPAResponseTypePermanentNegative,
    CPAResponseTypeAsynchronous
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
+ (CPAResponseType)responseTypeForResponse:(NSString *)response;

/**
 Parses a `get bootstrap info` response and returns the percentage completed.
 
 @param response The response to an `get bootstrap info` message.
 @return An integer between 0 and 100 representing the bootstrap progress of the Tor client.
 **/
+ (NSInteger)bootstrapProgressForResponse:(NSString *)response;

/**
 Parses a `get bootstrap info` response and returns the summary string.
 
 @param response The response to an `get bootstrap info` message.
 @return A string representing the bootstrap summary of the Tor client.
 **/
+ (NSString *)bootstrapSummaryForResponse:(NSString *)response;

@end
