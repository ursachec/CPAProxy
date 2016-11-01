//  CPAConfiguration.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAConfiguration.h"

@interface CPAConfiguration ()
@property (nonatomic, copy, readwrite) NSString *torDataDirectoryPath;
@end

@implementation CPAConfiguration
@synthesize socksPort = _socksPort;

+ (instancetype)configurationWithTorrcPath:(NSString *)torrcPath
                                 geoipPath:(NSString *)geoipPath
                      torDataDirectoryPath:(NSString *)torDataDirectoryPath
{
    return [[CPAConfiguration alloc] initWithTorrcPath:torrcPath
                                             geoipPath:geoipPath
                                  torDataDirectoryPath:torDataDirectoryPath];
}

- (instancetype)init
{
    return [self initWithTorrcPath:nil
                         geoipPath:nil
              torDataDirectoryPath:nil];
}

- (instancetype)initWithTorrcPath:(NSString *)torrcPath
                        geoipPath:(NSString *)geoipPath
             torDataDirectoryPath:(NSString *)torDataDirectoryPath
{
    self = [super init];
    if(!self) return nil;
    
    self.torrcPath = torrcPath;
    self.geoipPath = geoipPath;
    
    [self setupTorDirectoryWithPath:torDataDirectoryPath];
    
    return self;
}

- (NSString *)torDataDirectoryPath
{
    if (_torDataDirectoryPath != nil) {
        return _torDataDirectoryPath;
    }
    
    // Create a new temporary directory
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    
    [self setupTorDirectoryWithPath:path];
    
    return _torDataDirectoryPath;
}

- (BOOL)setupTorDirectoryWithPath:(NSString *)path
{
    //Cannot be documents directory for back reasons
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if ([path isEqualToString:documentsDirectory]) {
        return NO;
    }
    
    BOOL isDirectory = NO;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    
    if (!fileExists) {
        NSError *error = nil;
        [self createTorTemporaryDirectoryAtPath:path error:&error];
        if (!error) {
            isDirectory = YES;
            fileExists = YES;
        }
    }
    
    if (fileExists && isDirectory) {
        if ([self excludeDirectoryFromBackup:path error:nil]) {
            self.torDataDirectoryPath = path;
            return YES;
        }
    }
    return NO;
}

- (BOOL)createTorTemporaryDirectoryAtPath:(NSString *)path error:(NSError **)error
{
    return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:error];
}

- (BOOL)excludeDirectoryFromBackup:(NSString *)path error:(NSError **)error
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        return [[NSURL fileURLWithPath:path isDirectory:YES] setResourceValue: [NSNumber numberWithBool: YES]
                                                             forKey: NSURLIsExcludedFromBackupKey error:error];
    }
    return NO;
}

- (NSData *)torCookieData
{
    NSString *control_auth_cookie = [self.torDataDirectoryPath stringByAppendingPathComponent:@"control_auth_cookie"];
    NSData *cookie = [[NSData alloc] initWithContentsOfFile:control_auth_cookie];
    return cookie;
}

- (NSString *)torCookieDataAsHex
{
    NSData *cookieData = self.torCookieData;
    
    const unsigned char *chars = (const unsigned char*)cookieData.bytes;
    
    NSMutableString *hexString = [[NSMutableString alloc] init];
    for (int i = 0; i < cookieData.length; i++) {
        [hexString appendFormat:@"%02lx", (unsigned long)chars[i]];
    }
    
    return [NSString stringWithString:hexString];
}

- (NSString *)socksHost
{
    return @"127.0.0.1";
}

- (uint16_t)socksPort {
    if (_socksPort) {
        return _socksPort;
    }
    if (_useDefaultSocksPort) {
        _socksPort = 9050;
    } else {
        _socksPort = [self randomSOCKSPort];
    }
    return _socksPort;
}

- (uint16_t)controlPort {
    return self.socksPort + 1;
}

- (uint16_t)randomSOCKSPort
{
    NSInteger port = (arc4random() % 1000) + 60000;
    return port;
}

@end
