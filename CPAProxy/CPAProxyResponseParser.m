//
//  CPAProxyParser.m
//  Pods
//
//  Created by David Chiles on 10/8/14.
//
//

#import "CPAProxyResponseParser.h"
#import "CPAProxyTorCommandConstants.h"

@implementation CPAProxyResponseParser

+ (NSInteger)statusCodeForResponse:(NSString *)response
{
    NSInteger statusCode = 0;
    NSScanner *scanner = [NSScanner scannerWithString:response];
    [scanner scanInteger:&statusCode];
    return statusCode;
}

+ (CPAResponseType)responseTypeForResponse:(NSString *)response
{
    NSInteger statusCode = [self statusCodeForResponse:response];
    if (!(statusCode == 0)) {
        int digits =  (int) log10(statusCode);
        NSInteger signifcantDigit = statusCode / pow(10, digits);
        
        switch (signifcantDigit) {
            case 2:
                return CPAResponseTypeSuccess;
                break;
            case 4:
                return CPAResponseTypeTemporaryNegative;
                break;
            case 5:
                return CPAResponseTypePermanentNegative;
                break;
            case 6:
                return CPAResponseTypeAsynchronous;
                break;
                
            default:
                return CPAResponseTypeUnknown;
                break;
        }
    }
    else {
        return CPAResponseTypeUnknown;
    }
}

+ (NSInteger)bootstrapProgressForResponse:(NSString *)response
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

+ (NSString *)bootstrapSummaryForResponse:(NSString *)response
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

@end
