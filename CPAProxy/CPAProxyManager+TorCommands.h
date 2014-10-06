//  CPAProxyManager+TorControlAdditions.h
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAProxyManager.h"

/**
 This category adds methods to `CPAProxyManager` to send Tor control requests and process the responses.
 */
@interface CPAProxyManager (TorControlAdditions)

/**
 Writes a authentication message on Tor's control socket. It has the format "AUTHENTICATE %control_auth_cookie%", where %control_auth_cookie% is a hex representation of the cookie created by the Tor process on startup.
 
 The authentication message needs to be sent before any other control commands can be accepted.
 */
- (void)cpa_sendAuthenticate;

/**
 Writes a `get boostrap info` message on Tor's control socket. It has the format "GETINFO status/bootstrap-phase" and the response includes the status of the boostrap stage.
 */
- (void)cpa_sendGetBoostrapInfo;

/**
 Parses a `get boostrap info` response and returns the percentage completed.
 
 @param response The response to an `get boostrap info` message.
 @return An integer between 0 and 100 representing the boostrap progress of the Tor client.
 */
- (NSInteger)cpa_boostrapProgressForResponse:(NSString *)response;

/**
 Parses a `get boostrap info` response and returns the summary string.
 
 @param response The response to an `get boostrap info` message.
 @return A string representing the boostrap summary of the Tor client.
 */
- (NSString *)cpa_boostrapSummaryForResponse:(NSString *)response;

/**
 Parses a response from an authenticate message and returns if the authentication was successfull or not.
 
 @param response The response to an authenticate message.
 @return YES if the authenticate response was positive, otherwise NO.
 */
- (BOOL)cpa_isAuthenticatedForResponse:(NSString *)response;

@end
