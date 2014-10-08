//
//  GCDAsyncSocket+CPAProxy.h
//  Pods
//
//  Created by David Chiles on 10/6/14.
//
//

#import "GCDAsyncSocket.h"

@interface GCDAsyncSocket (CPAProxy)

- (void)cpa_writeString:(NSString *)string withEncoding:(NSStringEncoding)encoding timeout:(NSTimeInterval)timeout tag:(long)tag;

@end
