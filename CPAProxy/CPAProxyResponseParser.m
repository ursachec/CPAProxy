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

+ (CPAResonpseType)responseTypeForResponse:(NSString *)response
{
    NSInteger statusCode = [self statusCodeForResponse:response];
    if (!statusCode == 0) {
        int digits =  (int) log10(statusCode);
        NSInteger signifcantDigit = statusCode / pow(10, digits);
        
        switch (signifcantDigit) {
            case 2:
                return CPAResonpseTypeSucess;
                break;
            case 4:
                return CPAResonpseTypeTemporaryNegative;
                break;
            case 5:
                return CPAResonpseTypePermanentNegative;
                break;
            case 6:
                return CPAResonpseTypeAsynchronous;
                break;
                
            default:
                return CPAResonpseTypeUnkown;
                break;
        }
    }
    else {
        return CPAResonpseTypeUnkown;
    }
}

+ (NSInteger)boostrapProgressForResponse:(NSString *)response
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

+ (NSString *)boostrapSummaryForResponse:(NSString *)response
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
