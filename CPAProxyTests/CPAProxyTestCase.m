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
    
    self.torrcPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"torrc" ofType:nil];
    self.geoipPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"geoip" ofType:nil];
    XCTAssertNotNil(self.torrcPath, @"The torrc path should not be nil!");
    XCTAssertNotNil(self.geoipPath, @"The geoip path should not be nil!");
    
    [Expecta setAsynchronousTestTimeout:5.0f];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end
