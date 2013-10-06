//  CPAThread.h
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import <Foundation/Foundation.h>

@class CPAConfiguration;

/**
 `CPAThread` is a subclass of NSThread that uses data from a `CPAConfiguration` object to start a Tor client.
 
 When the thread is started, data from a `CPAConfiguration` file is used to start a Tor client by calling tor_main(int argc, char *argv[]).
 */

@interface CPAThread : NSThread

/**
 Initializes a `CPAThread` with the specified configuration.
 
 @param configuration The configuration for the thread.
 @return A newly initialized `CPAThread`.
 */
- (instancetype)initWithConfiguration:(CPAConfiguration *)configuration;

/**
 Returns the `CPAConfiguration` with which the object has been initialized.
 */
@property (nonatomic, strong, readonly) CPAConfiguration *configuration;

@end
