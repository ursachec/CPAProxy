//
//  CPAProxyTorCommandConstants.m
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import "CPAProxyTorCommandConstants.h"


NSString *const kCPAProxyEventCircuitStatus          = @"CIRC";
NSString *const kCPAProxyEventStreamStatus           = @"STREAM";
NSString *const kCPAProxyEventOnionRouterConnection  = @"ORCONN";
NSString *const kCPAProxyEventBandwidthLastSecond    = @"BW";
NSString *const kCPAProxyEventLogDegug               = @"DEBUG";
NSString *const kCPAProxyEventLogInfo                = @"INFO";
NSString *const kCPAProxyEventLogNotice              = @"NOTICE";
NSString *const kCPAProxyEventLogWarn                = @"WARN";
NSString *const kCPAProxyEventLogError               = @"ERR";
NSString *const KCPAProxyEventNewDescriptor          = @"NEWDESC";
NSString *const kCPAProxyEventNewAddressMapping      = @"ADDRMAP";
NSString *const kCPAProxyEventNewDescriptorsUploaded = @"AUTHDIR_NEWDESCS";
NSString *const kCPAProxyEventDescriptorChanged      = @"DESCCHANGED";
NSString *const kCPAProxyEventStatusGeneral          = @"STATUS_GENERAL";
NSString *const kCPAProxyEventStatusServer           = @"STATUS_SERVER";
NSString *const kCPAProxyEventStatusClient           = @"STATUS_CLIENT";
NSString *const kCPAProxyEventGuardNodesChanged      = @"GUARD";
NSString *const kCPAProxyEventNetworkStatusChanged   = @"NS";
NSString *const kCPAPRoxyEventStreamBandwidth        = @"STREAM_BW";
NSString *const kCPAProxyEventCountryClientStats     = @"CLIENTS_SEEN";
NSString *const kCPAProxyEventNewConsensus           = @"NEWCONSENSUS";
NSString *const kCPAProxyEventCircuitBuildTimeoutSet = @"BUILDTIMEOUT_SET";
NSString *const kCPAProxyEventConfigurationChanged   = @"CONF_CHANGED";
NSString *const kCPAProxyEventMinorCircutStatus      = @"CIRC_MINOR";
NSString *const kCPAProxyEventPluggableTransport     = @"TRANSPORT_LAUNCHED";


NSString *const kCPAProxyStatusBootstrapPhase       = @"status/bootstrap-phase";

NSString *const kCPAProxyCRLF                       = @"\r\n";

@implementation CPAProxyTorCommandConstants



@end
