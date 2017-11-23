//
//  CLEditManager.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/16.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CLVideoCutMode) {
    CLVideoCutModeScaleAspectFit    = 0,    // 填充模式
    CLVideoCutModeScaleAspectFill,          // 居中裁剪
};

@class CLEditManager;
@protocol CLVideoProcessingDelegate <NSObject>

@required

@optional

- (void)editManager:(CLEditManager *)editManager didFinishedOutputURL:(NSURL *)outputURL;
- (void)editManager:(CLEditManager *)editManager operationFailure:(NSError *)error;
- (void)editManager:(CLEditManager *)editManager handlingProgress:(CGFloat)progress;

@end

@interface CLEditManager : NSObject

@property (nonatomic, assign) id<CLVideoProcessingDelegate>delegate;
/**
 视频处理
 
 @param asset       video asset
 @param range       裁剪范围
 @param sizeScale   输出比例
 @param cutMode     裁剪模式
 @param fillColor   填充色
 */
- (void)exportEditVideoForAsset:(AVAsset *)asset
                          range:(CMTimeRange)range
                      sizeScale:(CGFloat)sizeScale
                        cutMode:(CLVideoCutMode)cutMode
                      fillColor:(UIColor *)fillColor;

/**
 视频处理

 @param asset       video asset
 @param range       裁剪范围
 @param sizeScale   输出比例
 @param isDistinguishWH 是否区分横竖比
 @param cutMode     裁剪模式
 @param fillColor   填充色
 @param mustRecode  比例正确时是否必须重新编码
 */
- (void)exportEditVideoForAsset:(AVAsset *)asset
                          range:(CMTimeRange)range
                      sizeScale:(CGFloat)sizeScale
                isDistinguishWH:(BOOL)isDistinguishWH
                        cutMode:(CLVideoCutMode)cutMode
                      fillColor:(UIColor *)fillColor
                     mustRecode:(BOOL)mustRecode;

// 取消处理
- (void)cancelExport;

#pragma mark -
#pragma mark -- Class Methods --
/**
 获取某时刻缩略图
 
 @param asset  videoAsset
 @param timeBySecond  时间,单位:秒
 @return 缩略图
 */
+ (UIImage *)requestThumbnailImageForAVAsset:(AVAsset *)asset
                                timeBySecond:(NSTimeInterval)timeBySecond;

/**
 获取缩略图数组
 */
+ (void)requestThumbnailImagesForAVAsset:(AVAsset *)asset
                                interval:(NSTimeInterval)interval
                                    size:(CGSize)size
                           eachThumbnail:(void (^)(UIImage *image))eachThumbnail
                                complete:(void (^)(AVAsset *asset, NSArray<UIImage *> *images))complete;

/**
 获取缩略图数组
 */
+ (void)requestThumbnailImagesForAVAsset:(AVAsset *)asset
                                duration:(NSTimeInterval)duration
                              imageCount:(NSInteger)imageCount
                                interval:(NSTimeInterval)interval
                                    size:(CGSize)size
                           eachThumbnail:(void (^)(UIImage *image))eachThumbnail
                                complete:(void (^)(AVAsset *asset, NSArray<UIImage *> *images))complete;

@end
