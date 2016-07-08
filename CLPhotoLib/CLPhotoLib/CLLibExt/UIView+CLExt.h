//
//  UIView+CLExt.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CLOscillatoryAnimationToBigger,
    CLOscillatoryAnimationToSmaller,
} CLOscillatoryAnimationType;

@interface UIView (CLExt)

@property (nonatomic) CGFloat cl_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat cl_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat cl_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat cl_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat cl_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat cl_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat cl_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat cl_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint cl_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  cl_size;        ///< Shortcut for frame.size.

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(CLOscillatoryAnimationType)type;

@end
