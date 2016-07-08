//
//  UIView+CLExt.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "UIView+CLExt.h"

@implementation UIView (CLExt)

- (CGFloat)cl_left {
    return self.frame.origin.x;
}

- (void)setCl_left:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)cl_top {
    return self.frame.origin.y;
}

- (void)setCl_top:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)cl_right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setCl_right:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)cl_bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setCl_bottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGFloat)cl_width {
    return self.frame.size.width;
}

- (void)setCl_width:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)cl_height {
    return self.frame.size.height;
}

- (void)setCl_height:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)cl_centerX {
    return self.center.x;
}

- (void)setCl_centerX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)cl_centerY {
    return self.center.y;
}

- (void)setCl_centerY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGPoint)cl_origin {
    return self.frame.origin;
}

- (void)setCl_origin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)cl_size {
    return self.frame.size;
}

- (void)setCl_size:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(CLOscillatoryAnimationType)type{
    NSNumber *animationScale1 = type == CLOscillatoryAnimationToBigger ? @(1.15) : @(0.5);
    NSNumber *animationScale2 = type == CLOscillatoryAnimationToBigger ? @(0.92) : @(1.15);
    
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
        [layer setValue:animationScale1 forKeyPath:@"transform.scale"];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
            [layer setValue:animationScale2 forKeyPath:@"transform.scale"];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut animations:^{
                [layer setValue:@(1.0) forKeyPath:@"transform.scale"];
            } completion:nil];
        }];
    }];
}


@end
