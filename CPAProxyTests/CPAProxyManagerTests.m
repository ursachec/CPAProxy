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
    
    [Expecta setAsynchronousTestTimeout:60 * 5]; // 5 minutes. Sometimes Tor takes a long time to bootstrap
    
    self.configuration = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath torDataDirectoryPath:nil];
    self.proxyManager = [CPAProxyManager proxyWithConfiguration:self.configuration];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [self.proxyManager.torThread cancel];
}

- (void)testSuccessfulProxySetup
{
    __block NSError *blockError = nil;
    __block NSString *blockSocksHost = nil;
    __block NSUInteger blockSocksPort = 0;
    
    [self.proxyManager setupWithSuccess:^(NSString *socksHost, NSUInteger socksPort) {
        blockSocksHost = socksHost;
        blockSocksPort = socksPort;
    } failure:^(NSError *error) {
        blockError = error;
    }];
    
    expect(blockError).will.beNil();
    expect(blockSocksHost).willNot.beNil();
    expect(blockSocksPort).willNot.equal(0);
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
