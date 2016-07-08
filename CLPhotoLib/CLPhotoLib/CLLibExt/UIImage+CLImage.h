//
//  UIImage+CLImage.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/30.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (CLImage)
/**
 *  读取CLPhotoLib.bundle中的图片
 *
 *  @param name 图片名
 *
 *  @return 图片
 */
+ (UIImage *)imageNamedFromCLBundle:(NSString *)name;

/**
 *  颜色转图片
 *
 *  @param color 颜色
 *
 *  @return 图片
 */
+ (UIImage *)imageWithCLColor:(UIColor *)color;


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
