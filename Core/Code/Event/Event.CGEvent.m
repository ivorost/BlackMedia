//
//  Event.m
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#import "Event.CGEvent.h"

@implementation NSData (CGEvent)

+ (nullable instancetype)dataWithCGEvent:(nonnull CGEventRef)event {
    // in Xcode 11.7 CGEvent.data cause compiler crash so it's workaround.
    // Should be retested with newest version and removed if fixed.
    return (__bridge NSData *)CGEventCreateData(CFAllocatorGetDefault(), event);
}

@end
