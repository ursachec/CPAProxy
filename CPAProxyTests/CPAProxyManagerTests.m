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
    
    [Expecta setAsynchronousTestTimeout:30];
    
    self.configuration = [CPAConfiguration configurationWithTorrcPath:self.torrcPath geoipPath:self.geoipPath];
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

@end
