//
//  CLPhotoManager.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/10/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "CLPickerRootController.h"

#define CLPhotoShareManager     [CLPhotoManager shareManager]
#define CLMinSize               CLPhotoShareManager.minSize
#define CLAllowSelectGif        CLPhotoShareManager.allowSelectGif
#define CLAllowSelectLivePhoto  CLPhotoShareManager.allowSelectLivePhoto
#define CLSortAscending         CLPhotoShareManager.sortAscending

@class CLAlbumModel;
@class CLPhotoModel;
@interface CLPhotoManager : NSObject

+ (instancetype)shareManager;

@property (nonatomic, assign) CGSize minSize;
@property (nonatomic, assign) BOOL allowSelectGif;
@property (nonatomic, assign) BOOL allowSelectLivePhoto;
@property (nonatomic, assign) BOOL sortAscending;

#pragma mark -- Object Methods --
// 获得（相册交卷/所有图片）所在的相册
- (void)getCameraRollAlbumWithSelectMode:(CLPickerSelectMode)selectMode complete:(void (^)(CLAlbumModel *albumModel))complete;

// 获得 所有相册/相册数组
- (void)getAlbumListWithSelectMode:(CLPickerSelectMode)selectMode completion:(void (^)(NSArray<CLAlbumModel *> *models))completion;

// 获取选中图片数组
- (void)requestImagesWithModelArray:(NSMutableArray<CLPhotoModel *> *)modelArray isOriginal:(BOOL)isOriginal completion:(void (^)(NSArray<UIImage *> *photos, NSArray *assets))completion;

// 获取LivePhoto
- (void)requestLivePhotoForAsset:(PHAsset *)asset completion:(void (^)(PHLivePhoto *livePhoto, NSDictionary *info))completion PHOTOS_AVAILABLE_IOS_TVOS(9_1, 10_0);

// 获取图片data
- (void)requestOriginalImageDataForAsset:(PHAsset *)asset completion:(void (^)(NSData *data, NSDictionary *info))completion;

// 获取视频AVPlayerItem
- (void)requestVideoPlayerItemForAsset:(PHAsset *)asset completion:(void (^)(AVPlayerItem *item, NSDictionary *info))completion;

// 获取视频AVAsset
- (void)requestVideoAssetForAsset:(PHAsset *)asset completion:(void (^)(AVAsset *asset, NSDictionary *info))completion;

// 获取原图
- (PHImageRequestID)requestOriginalImageForAsset:(PHAsset *)asset completion:(void (^)(UIImage *image, NSDictionary *))completion;

// 获取自定义size的图片
- (PHImageRequestID)requestCustomImageForAsset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage *image, NSDictionary *info))completion;

// 获取size&resizeMode的图片
- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void (^)(UIImage *image, NSDictionary *info))completion;

#pragma mark -
#pragma mark -- Public Class Methods --
+ (void)judgeAssetisInLocalAblum:(PHAsset *)asset completion:(void (^)(BOOL isInLocal))completion;

// gif data转图片
+ (UIImage *)transformToGifImageWithData:(NSData *)data;

// 获取Photos大小
+ (void)getPhotosBytesWithArray:(NSArray<CLPhotoModel *> *)photos completion:(void (^)(NSString *photosBytes))completion;

// 获取PHAsset.localIdentifier数组
+ (NSArray *)getLocalIdentifierArrayWithArray:(NSArray<CLPhotoModel *> *)array;

// 检测是否选中
+ (BOOL)checkSelcectedWithModel:(CLPhotoModel *)model identifiers:(NSArray *)identifiers;

// 检测数组中包含的选中图片
+ (NSInteger)checkSelcectModelInArray:(NSArray<CLPhotoModel *> *)dataArray selArray:(NSArray<CLPhotoModel *> *)selArray;

// 保存图片到相册
+ (void)saveImageToAblum:(UIImage *)image completion:(void (^)(BOOL success, PHAsset *asset))completion;

// 保存视频到相册
+ (void)saveVideoToAblum:(NSURL *)url completion:(void (^)(BOOL success, PHAsset *asset))completion;

@end
