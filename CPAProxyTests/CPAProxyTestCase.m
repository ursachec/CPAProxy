//
//  CPAProxyTestCase.m
//  CPAProxy
//
//  Created by Claudiu-Vlad Ursache on 07.10.13.
//  Copyright (c) 2013 CPAProxy. All rights reserved.
//

#import "CPAProxyTestCase.h"

@interface CPAProxyTestCase ()
@property(nonatomic, copy, readwrite) NSString *torrcPath;
@property(nonatomic, copy, readwrite) NSString *geoipPath;
@end

@implementation CPAProxyTestCase

- (void)setUp
{
    [super setUp];
    NSURL *cpaProxyBundleURL = [[NSBundle bundleForClass:NSClassFromString(@"CPAProxyManager")] URLForResource:@"CPAProxy" withExtension:@"bundle"];
    XCTAssertNotNil(cpaProxyBundleURL, @"cpaProxyBundleURL should not be nil!");
    NSBundle *cpaProxyBundle = [NSBundle bundleWithURL:cpaProxyBundleURL];
    self.torrcPath = [cpaProxyBundle pathForResource:@"torrc" ofType:nil];
    self.geoipPath = [cpaProxyBundle pathForResource:@"geoip" ofType:nil];
    XCTAssertNotNil(self.torrcPath, @"The torrc path should not be nil!");
    XCTAssertNotNil(self.geoipPath, @"The geoip path should not be nil!");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end
