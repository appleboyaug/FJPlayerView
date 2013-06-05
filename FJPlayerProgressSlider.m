//
//  FJPlayerProgressSlider.m
//  AbleSky
//
//  Created by fengjia on 5/24/13.
//  Copyright (c) 2013 fengjia. All rights reserved.
//

#import "FJPlayerProgressSlider.h"

@implementation FJPlayerProgressSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (CGRect)maximumValueImageRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 2);
}
- (CGRect)minimumValueImageRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 2);
}
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, 2);
}
//- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value {
//    return CGRectMake(bounds.origin.x * value, bounds.origin.y, 5, 5);
//}

@end
