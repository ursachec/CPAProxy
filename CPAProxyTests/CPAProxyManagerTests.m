//
//  CPAProxyManagerTests.m
//  CPAProxy
//
//  Created by Claudiu-Vlad Ursache on 07.10.13.
//  Copyright (c) 2013 CPAProxy. All rights reserved.
//

@import XCTest;
#import "CPAProxyTestCase.h"
@import CPAProxy;
@import ProxyKit;
@import CocoaLumberjack;

static NSString * const kIPTestDomain = @"wtfismyip.com";


@interface CPAProxyManagerTests : CPAProxyTestCase <GCDAsyncSocketDelegate>
@property (nonatomic, strong, readwrite) CPAProxyManager *proxyManager;
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@property (nonatomic) BOOL torIsRunning;

@property (nonatomic, strong) NSMutableArray <NSString*> *ipAddresses;
@property (nonatomic, strong) XCTestExpectation *socksIsolationExepectation;
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
    //[DDLog addLogger:[DDTTYLogger sharedInstance]];

    
    // only allow one instance of Tor
    if (sharedProxyManager != nil) {
        self.proxyManager = sharedProxyManager;
        self.configuration = self.proxyManager.configuration;
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

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [DDLog removeAllLoggers];
    
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


- (void)testTorDataDirectory
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    CPAConfiguration *config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:documentsDirectory];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0,@"No Tor directory path");
    XCTAssertFalse([config.torDataDirectoryPath isEqualToString:documentsDirectory],@"Tor directory is equal to documents directory");
    
    NSString *directory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.cpaproxy"];
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:directory];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0, @"No Tor data directory path");
    
    // This test fails on Travis due to permissions problems
    //XCTAssertTrue([config.torDataDirectoryPath isEqualToString:directory],@"Tor data directory path incorrect %@, expected %@", config.torDataDirectoryPath, directory);
    
    config = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    XCTAssertTrue([config.torDataDirectoryPath length] > 0,@"NO tor Data directory Path");
}

- (void) testTorSOCKSIsolation {
    self.ipAddresses = [NSMutableArray array];
    GCDAsyncProxySocket *socket1 = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [socket1 setProxyHost:self.configuration.socksHost port:self.configuration.socksPort version:GCDAsyncSocketSOCKSVersion5];
    [socket1 setProxyUsername:[[NSUUID UUID] UUIDString] password:[[NSUUID UUID] UUIDString]];
    
    GCDAsyncProxySocket *socket2 = [[GCDAsyncProxySocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [socket2 setProxyHost:self.configuration.socksHost port:self.configuration.socksPort version:GCDAsyncSocketSOCKSVersion5];
    [socket2 setProxyUsername:[[NSUUID UUID] UUIDString] password:[[NSUUID UUID] UUIDString]];
    
    uint16_t port = 443;
    NSError *error = nil;
    
    [socket1 connectToHost:kIPTestDomain onPort:port error:&error];
    XCTAssertNil(error);
    [socket2 connectToHost:kIPTestDomain onPort:port error:&error];
    XCTAssertNil(error);
    
    self.socksIsolationExepectation = [self expectationWithDescription:@"SOCKS Auth Isolation"];
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [sock startTLS:nil];
    NSString * getRequest = @"GET /text HTTP/1.0\r\n\r\n";
    [sock writeData:[getRequest dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1234];
    [sock readDataWithTimeout:-1 tag:1234];
}

- (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray *lines = [responseString componentsSeparatedByString:@"\n"];
    NSString *ip = lines[lines.count - 2];
    
    NSLog(@"ip: %@", ip);
    
    [self.ipAddresses addObject:ip];
    
    if (self.ipAddresses.count == 2) {
        NSString *address1 = [self.ipAddresses firstObject];
        NSString *address2 = [self.ipAddresses lastObject];
        XCTAssertNotEqualObjects(address1, address2);
        [self.socksIsolationExepectation fulfill];
    }
}

- (void) socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"socketDidDisconnect %@", err);
}


@end
