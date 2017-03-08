//
//  CPAProxyTestCase.h
//  CPAProxy
//
//  Created by Claudiu-Vlad Ursache on 07.10.13.
//  Copyright (c) 2013 CPAProxy. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface CPAProxyTestCase : XCTestCase
@property(nonatomic, copy, readonly) NSString *torrcPath;
@property(nonatomic, copy, readonly) NSString *geoipPath;
@end
