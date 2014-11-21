//  CPAThread.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAThread.h"
#import "CPAConfiguration.h"
#import "tor_cpaproxy.h"

static NSString *const kTorArgsValueIsolateDestPort = @"IsolateDestPort";
static NSString *const kTorArgsValueIsolateDestAddr = @"IsolateDestAddr";

const char *kTorArgsKeyARG0 = "tor";
const char *kTorArgsKeyDataDirectory = "DataDirectory";
const char *kTorArgsKeyControlPort = "ControlPort";
const char *kTorArgsKeyKeySOCKSPort = "SocksPort";
const char *kTorArgsKeyGeoIPFile = "GeoIPFile";
const char *kTorArgsKeyTorrcFile = "-f";
const char *kTorArgsKeyLog = "Log";

#ifndef DEBUG
const char *kTorArgsValueLogLevel = "warn stderr";
#else
const char *kTorArgsValueLogLevel = "notice stderr";
#endif

@interface CPAThread ()
@property (nonatomic, strong, readwrite) CPAConfiguration *configuration;
@end

@implementation CPAThread

- (instancetype)init
{
    CPAConfiguration *datasource = [[CPAConfiguration alloc] init];
    return [self initWithConfiguration:datasource];
}

- (instancetype)initWithConfiguration:(CPAConfiguration *)configuration
{
    self = [super init];
    if(!self) return nil;
    
    self.configuration = configuration;
    
    return self;
}

- (void)main
{
    NSString *dataDir = self.configuration.torDataDirectoryPath;
    NSString *torrcPath = self.configuration.torrcPath;
    NSString *geoipPath = self.configuration.geoipPath;
    NSString *controlPort = [NSString stringWithFormat:@"%lu", (unsigned long)self.configuration.controlPort];
    NSMutableString *socksPort = [NSMutableString stringWithFormat:@"localhost:%lu", (unsigned long)self.configuration.socksPort];
    if (self.configuration.isolateDestinationAddress) {
        [socksPort appendFormat:@" %@", kTorArgsValueIsolateDestAddr];
    }
    if (self.configuration.isolateDestinationPort) {
        [socksPort appendFormat:@" %@", kTorArgsValueIsolateDestPort];
    }
    
    const char *argv[] = { 
        kTorArgsKeyARG0, 
        kTorArgsKeyDataDirectory, [dataDir UTF8String], 
        kTorArgsKeyControlPort, [controlPort UTF8String],
        kTorArgsKeyKeySOCKSPort, [socksPort UTF8String],
        kTorArgsKeyGeoIPFile, [geoipPath UTF8String], 
        kTorArgsKeyTorrcFile, [torrcPath UTF8String],
        kTorArgsKeyLog, kTorArgsValueLogLevel, 
        NULL 
    };
    
    tor_main(13, argv);
}

@end
