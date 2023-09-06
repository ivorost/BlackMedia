//
//  Event.h
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface NSData (CGEvent)

+ (nullable instancetype)dataWithCGEvent:(nonnull CGEventRef)event;

@end
