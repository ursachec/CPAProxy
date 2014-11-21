//
//  CPAProxyTorCommandConstants.h
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import <Foundation/Foundation.h>

// For more information on what each event is look at the tor Tor control protocol documentation 3.4. SETEVENTS
extern NSString *const kCPAProxyEventCircuitStatus;
extern NSString *const kCPAProxyEventStreamStatus;
extern NSString *const kCPAProxyEventOnionRouterConnection;
extern NSString *const kCPAProxyEventBandwidthLastSecond;
extern NSString *const kCPAPRoxyEventLogDegug;
extern NSString *const kCPAPRoxyEventLogInfo;
extern NSString *const kCPAPRoxyEventLogNotice;
extern NSString *const kCPAPRoxyEventLogWarn;
extern NSString *const kCPAPRoxyEventLogError;
extern NSString *const KCPAProxyEventNewDescriptor;
extern NSString *const kCPAProxyEventNewAddressMapping;
extern NSString *const kCPAProxyEventNewDescriptorsUploaded;
extern NSString *const kCPAProxyEventDescriptorChanged;
extern NSString *const kCPAProxyEventStatusGeneral;
extern NSString *const kCPAProxyEventStatusServer;
extern NSString *const kCPAProxyEventStatusClient;
extern NSString *const kCPAProxyEventGuardNodesChanged;
extern NSString *const kCPAProxyEventNetworkStatusChanged;
extern NSString *const kCPAPRoxyEventStreamBandwidth;
extern NSString *const kCPAProxyEventCountryClientStats;
extern NSString *const kCPAProxyEventNewConsensus;
extern NSString *const kCPAProxyEventCircuitBuildTimeoutSet;
extern NSString *const kCPAProxyEventConfigurationChanged;
extern NSString *const kCPAProxyEventMinorCircutStatus;
extern NSString *const kCPAProxyEventPluggableTransport;

extern NSString *const kCPAProxyStatusBootstrapPhase;

extern NSString *const kCPAProxyCRLF;

@interface CPAProxyTorCommandConstants : NSObject



@end
