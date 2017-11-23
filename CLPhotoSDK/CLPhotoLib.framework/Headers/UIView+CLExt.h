//
//  UIView+CLExt.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CLOscillatoryAnimationToBigger,
    CLOscillatoryAnimationToSmaller,
} CLOscillatoryAnimationType;

@interface UIView (CLExt)

@property CGPoint origin;
@property CGSize size;

@property (readonly) CGPoint bottomLeft;
@property (readonly) CGPoint bottomRight;
@property (readonly) CGPoint topRight;

@property CGFloat height;
@property CGFloat width;

@property CGFloat top;
@property CGFloat left;

@property CGFloat bottom;
@property CGFloat right;

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(CLOscillatoryAnimationType)type;

@end
