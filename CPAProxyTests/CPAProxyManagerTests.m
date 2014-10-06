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
    __block NSInteger progressInt = 0;
    
    [self.proxyManager setupWithCompletion:^(NSString *socksHost, NSUInteger socksPort, NSError *error) {
        blockSocksHost = socksHost;
        blockSocksPort = socksPort;
        blockError = error;
    } progress:^(NSInteger progress, NSString *summaryString) {
        expect(summaryString).willNot.beNil();
        progressInt = progress;
    }];
    
    expect(blockError).will.beNil();
    expect(blockSocksHost).willNot.beNil();
    expect(blockSocksPort).willNot.equal(0);
    expect(progressInt).willNot.equal(0);
}

@end
