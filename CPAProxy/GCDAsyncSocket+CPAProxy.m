//
//  GCDAsyncSocket+CPAProxy.m
//  Pods
//
//  Created by David Chiles on 10/6/14.
//
//

#import "GCDAsyncSocket+CPAProxy.h"

@implementation GCDAsyncSocket (CPAProxy)

- (void)cpa_writeString:(NSString *)string withEncoding:(NSStringEncoding)encoding timeout:(NSTimeInterval)timeout tag:(long)tag
{
    [self writeData:[string dataUsingEncoding:encoding] withTimeout:timeout tag:tag];
}

@end
