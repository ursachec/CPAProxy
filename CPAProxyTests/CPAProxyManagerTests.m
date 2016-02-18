//
//  CPAProxyManagerTests.m
//  CPAProxy
//
//  Created by Claudiu-Vlad Ursache on 07.10.13.
//  Copyright (c) 2013 CPAProxy. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CPAProxyTestCase.h"
@import CPAProxy;


@interface CPAProxyManagerTests : CPAProxyTestCase
@property (nonatomic, strong, readwrite) CPAProxyManager *proxyManager;
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@property (nonatomic) BOOL torIsRunning;
@end

@implementation CPAProxyManagerTests

/**
 *  This is required because Tor can only ever be initialized ONCE by an application
 *  because the thread doesn't get cleaned up after 'exit'.
 */
static CPAProxyManager *sharedProxyManager = nil;

- (void)setUp
{
    [super setUp];
    
    // only allow one instance of Tor
    if (sharedProxyManager != nil) {
        self.proxyManager = sharedProxyManager;
        return;
    }
    self.configuration = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    self.configuration.isolateDestinationPort = YES;
    self.configuration.isolateDestinationAddress = YES;
    sharedProxyManager = [CPAProxyManager proxyWithConfiguration:self.configuration];
    self.proxyManager = sharedProxyManager;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"startTorExpectation"];
    XCTestExpectation *progressExpectation = [self expectationWithDescription:@"progress"];
    
    [self.proxyManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
        XCTAssertNil(error, @"Error setting up");
        XCTAssertTrue([socksHost length] > 0, @"No SOCKS host string");
        XCTAssertTrue(socksPort > 0, @"NO SOCKS port");
        [expectation fulfill];
    } progress:^(NSInteger progress, NSString *summaryString) {
        XCTAssertTrue(progress >= 0 && progress <= 100, @"Invalid progress");
        XCTAssertTrue([summaryString length] > 0, @"No summary String");
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [progressExpectation fulfill];
        });
    } callbackQueue:dispatch_get_main_queue()];
    
    [self waitForExpectationsWithTimeout:3*60 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Time out Error");
        }
    }];
}

- (void) testSOCKSPortConfiguration {
    // The callbackQueue must NOT be the main queue because
    // Expecta blocks the main queue and the tests will fail
    dispatch_queue_t callbackQueue = dispatch_queue_create("socks callback queue", 0);
    
    __block NSString *expectedSocksPortResponse = [NSString stringWithFormat:@"250 SocksPort=localhost:%lu IsolateDestAddr IsolateDestPort", (unsigned long)self.proxyManager.SOCKSPort];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test SOCKS Port config"];
    
    // Test SOCKS port configuration
    [self.proxyManager cpa_getConfigurationVariable:@"SOCKSPort" completionBlock:^(NSString *responseString, NSError *error) {
        XCTAssertNil(error, @"Error getting socks config");
        XCTAssertTrue([responseString isEqualToString:expectedSocksPortResponse], @"Error SOCKS response string");
        [expectation fulfill];
    } completionQueue:callbackQueue];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void) testSendingHUP {
    dispatch_queue_t callbackQueue = dispatch_queue_create("socks callback queue", 0);
    __block NSString *expectedHUPResponse = @"250 OK";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Test SOCKS Port config"];
    
    [self.proxyManager cpa_sendSignal:@"HUP" completionBlock:^(NSString *responseString, NSError *error) {
        XCTAssertNil(error, @"Error sedning HUP");
        XCTAssertTrue([responseString isEqualToString:expectedHUPResponse], @"Error HUP response string");
        [expectation fulfill];
    } completionQueue:callbackQueue];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];    
}


- (void)testTorDataDirectory
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    CPAConfiguration *config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:documentsDirectory];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0,@"No Tor directory path");
    XCTAssertFalse([config.torDataDirectoryPath isEqualToString:documentsDirectory],@"Tor directory is equal to documents directory");
    
    NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.cpaproxy"];
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:directory];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0, @"No Tor data directory path");
    XCTAssertTrue([config.torDataDirectoryPath isEqualToString:directory],@"Tor data directory path incorrect");
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0,@"NO tor Data directory Path");
}

@end
