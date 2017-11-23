//
//  UIImage+CLExt.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (CLExt)

+ (UIImage *)imageNamedFromBundle:(NSString *)name;

/**
 *  颜色转图片
 *
 *  @param color 颜色
 *
 *  @return 图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)imageWithColor:(UIColor *)color rectSize:(CGRect)imageSize;

// 图片根据尺寸缩放
+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size;

// 图片方向处理
+ (UIImage *)fixOrientation:(UIImage *)aImage isRotate:(BOOL)isRotate;


/**
 *  返回一个Size
 *
 *  @param imageSize 原图size
 *  @param size      图片小的一边 不得超过的约束尺寸
 *
 *  @return 返回size
 */
+ (CGSize)getSizeWithImageSize:(CGSize)imageSize toSize:(CGSize)size;

@end
