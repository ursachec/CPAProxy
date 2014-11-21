//  CPAProxyManager+TorControlAdditions.h
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAProxyManager.h"
#import "CPAProxyCommand.h"

/**
 This category adds methods to `CPAProxyManager` to send Tor control requests and process the responses.
 */
@interface CPAProxyManager (TorControlAdditions)

/**
 Writes a authentication message on Tor's control socket. It has the format "AUTHENTICATE %control_auth_cookie%", where %control_auth_cookie% is a hex representation of the cookie created by the Tor process on startup.
 
 The authentication message needs to be sent before any other control commands can be accepted.
 */
- (void)cpa_sendAuthenticateWithCompletion:(CPAProxyCommandResponseBlock)completion
                           completionQueue:(dispatch_queue_t)completionQueue;

/**
 Writes a `get bootstrap info` message on Tor's control socket. It has the format "GETINFO status/bootstrap-phase" and the response includes the status of the bootstrap stage.
 */
- (void)cpa_sendGetBootstrapInfoWithCompletion:(CPAProxyCommandResponseBlock)completion
                              completionQueue:(dispatch_queue_t)completionQueue;

/**
 Request the value of a configuration variable from Tor's control socket.
 */
- (void)cpa_getConfigurationVariable:(NSString*)configurationVariable
                     completionBlock:(CPAProxyCommandResponseBlock)completionBlock
                     completionQueue:(dispatch_queue_t)completionQueue;

/**
 * Used to send a SIGNAL to Tor's control socket.
 * "RELOAD" / "SHUTDOWN" / "DUMP" / "DEBUG" / "HALT" /
 * "HUP" / "INT" / "USR1" / "USR2" / "TERM" / "NEWNYM" /
 * "CLEARDNSCACHE"
 */
- (void)cpa_sendSignal:(NSString*)signal
       completionBlock:(CPAProxyCommandResponseBlock)completionBlock
       completionQueue:(dispatch_queue_t)completionQueue;


/**
 'Request the server to inform the client about interesting events' any events not listed will be turned off
 sending nil or an empty array will turn off all events reporting
 */
- (void)cpa_setEvents:(NSArray *)eventsArray
             extended:(BOOL)extended
           completion:(CPAProxyCommandResponseBlock)completion
      completionQueue:(dispatch_queue_t)completionQueue;

@end
