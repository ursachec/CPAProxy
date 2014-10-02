//  CPAProxyManager+TorControlAdditions.m
//
//  Copyright (c) 2013 Claudiu-Vlad Ursache.
//  See LICENCE for licensing information
//

#import "CPAProxyManager+TorCommands.h"
#import "CPAThread.h"
#import "CPAConfiguration.h"
#import "CPASocketManager.h"

@implementation CPAProxyManager (TorControlAdditions)

- (void)cpa_sendAuthenticate
{
    NSString *torCookieAsHex = self.configuration.torCookieDataAsHex;
    NSString *authMsg = [NSString stringWithFormat:@"AUTHENTICATE %@\n", torCookieAsHex];
    [self.socketManager writeString:authMsg encoding:NSUTF8StringEncoding];
}

- (void)cpa_sendGetBoostrapInfo
{
    NSString *msgBootstrapInfo = @"GETINFO status/bootstrap-phase\n"; 
    [self.socketManager writeString:msgBootstrapInfo encoding:NSUTF8StringEncoding];
}

- (NSInteger)cpa_boostrapProgressForResponse:(NSString *)response
{    
    NSString *progressString = @"BOOTSTRAP PROGRESS=";
    NSInteger progess = 0;
    
    NSScanner *scanner = [NSScanner scannerWithString:response];
    [scanner scanUpToString:progressString intoString:NULL];
    
    BOOL stringFound = [scanner scanString:progressString intoString:NULL];
    if (stringFound) {
        [scanner scanInteger:&progess];
    }
    
    return progess;
}

- (NSString *)cpa_boostrapSummaryForResponse:(NSString *)response
{
    NSString *progressString = @"SUMMARY=";
    NSString *summaryString = nil;
    
    NSScanner *scanner = [NSScanner scannerWithString:response];
    scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"\""];
    [scanner scanUpToString:progressString intoString:NULL];
    
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:NULL];
    [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&summaryString];
    return summaryString;
}

- (BOOL)cpa_isAuthenticatedForResponse:(NSString *)response
{
    if ([response rangeOfString:@"250 OK"].location != NSNotFound) {
        return YES;
    }
    return NO;
}


@end
