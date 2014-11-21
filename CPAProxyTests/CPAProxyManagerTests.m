//
//  CPAProxyManagerTests.m
//  CPAProxy
//
//  Created by Claudiu-Vlad Ursache on 07.10.13.
//  Copyright (c) 2013 CPAProxy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CPAProxyTestCase.h"
#import "CPAConfiguration.h"
#import "CPAProxyManager.h"
#import "CPAProxyManager+TorCommands.h"
#import "CPAThread.h"

@interface CPAProxyManagerTests : CPAProxyTestCase
@property (nonatomic, strong, readwrite) CPAProxyManager *proxyManager;
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@end

@implementation CPAProxyManagerTests

- (void)setUp
{
    [super setUp];
    
    [Expecta setAsynchronousTestTimeout:60 * 3]; // 3 minutes. Sometimes Tor takes a long time to bootstrap
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];    
}

/**
 *  It is currently impossible to run multiple tests that test Tor bootstrap/connection
 *  because cancelling the Tor thread doesn't result in a clean exist and libevent/kqueue
 *  will complain when you try to start the next test.
 *  
 *  Although not quite idempotent, perhaps a better approach will be to connect only once globally
 *  and send the HUP signal when a reload is desired in each test.
 */
- (void)testSuccessfulProxySetup
{
    self.configuration = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    self.configuration.isolateDestinationPort = YES;
    self.configuration.isolateDestinationAddress = YES;
    self.proxyManager = [CPAProxyManager proxyWithConfiguration:self.configuration];
    
    // The callbackQueue must NOT be the main queue because
    // Expecta blocks the main queue and the tests will fail
    dispatch_queue_t callbackQueue = dispatch_queue_create("socks callback queue", 0);
    
    __block NSString *socksResponseString = nil;
    __block NSString *HUPResponseString = nil;

    __block NSError *blockError = nil;
    __block NSString *blockSocksHost = nil;
    __block NSUInteger blockSocksPort = 0;
    __block NSInteger blockProgressInt = 0;
    __block NSString *blockSummaryString = nil;
    NSString *expectedSocksPortResponse = [NSString stringWithFormat:@"250 SocksPort=localhost:%lu IsolateDestAddr IsolateDestPort", self.proxyManager.SOCKSPort];
    NSString *expectedHUPResponse = @"250 OK";
    
    [self.proxyManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
        blockSocksHost = socksHost;
        blockSocksPort = socksPort;
        blockError = error;
        if (!error) {
            // Test SOCKS port configuration
            [self.proxyManager cpa_getConfigurationVariable:@"SOCKSPort" completionBlock:^(NSString *responseString, NSError *error) {
                if (!error) {
                    socksResponseString = responseString;
                } else {
                    NSLog(@"Error with getting socks config: %@", error);
                }
                // Test sending a signal
                [self.proxyManager cpa_sendSignal:@"HUP" completionBlock:^(NSString *responseString, NSError *error) {
                    HUPResponseString = responseString;
                    if (error) {
                        NSLog(@"Error with getting socks config: %@", error);
                    }
                } completionQueue:callbackQueue];
            } completionQueue:callbackQueue];
        } else {
            NSLog(@"Error with setup: %@", error);
        }
    } progress:^(NSInteger progress, NSString *summaryString) {
        blockProgressInt = progress;
        blockSummaryString = summaryString;
    } callbackQueue:callbackQueue];
    
    expect(socksResponseString).will.equal(expectedSocksPortResponse);
    expect(HUPResponseString).will.equal(expectedHUPResponse);
    expect(blockError).will.beNil();
    expect(blockSocksHost).willNot.beNil();
    expect(blockSocksPort).willNot.equal(0);
    expect(blockProgressInt).willNot.equal(0);
    expect(blockSummaryString).willNot.beNil();
}

- (void)testTorDataDirectory
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    CPAConfiguration *config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:documentsDirectory];
    
    expect(config.torDataDirectoryPath).willNot.beNil();
    expect(config.torDataDirectoryPath).willNot.equal(documentsDirectory);
    
    NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.cpaproxy"];
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:directory];
    expect(config.torDataDirectoryPath).willNot.beNil();
    expect(config.torDataDirectoryPath).will.equal(directory);
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    expect(config.torDataDirectoryPath).willNot.beNil();
}

@end
