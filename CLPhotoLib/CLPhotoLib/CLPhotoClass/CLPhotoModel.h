//
//  CLPhotoModel.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSUInteger, CLAssetMediaType) {
    CLAssetMediaTypeUnknown,
    CLAssetMediaTypeImage,
    CLAssetMediaTypeGif,
    CLAssetMediaTypeLivePhoto,
    CLAssetMediaTypeVideo,
    CLAssetMediaTypeAudio,
    CLAssetMediaTypeNetImage,
};

@interface CLPhotoModel : NSObject

@property (nonatomic, strong) PHAsset *asset;           // asset对象
@property (nonatomic, assign) BOOL  isSelected;         // The select status of a photo, default is No
@property (nonatomic, assign) CLAssetMediaType type;
@property (nonatomic, copy)   NSString *timeFormat;     // video or audio duration
@property (nonatomic, assign) CGFloat duration;         // video or audio duration

+ (instancetype)modelWithAsset:(PHAsset *)asset;
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(CLAssetMediaType)type;
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(CLAssetMediaType)type duration:(CGFloat)duration;

+ (NSString *)timeWithFormat:(CGFloat)dur;

+ (CLAssetMediaType)transformAssetType:(PHAsset *)asset;

@end

@interface CLAlbumModel : NSObject

@property (nonatomic, copy)   NSString  *title;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) PHFetchResult *result;
// 相册第一张图asset对象
@property (nonatomic, strong) PHAsset *firstAsset;

@property (nonatomic, copy)   NSArray <CLPhotoModel *> *models;
@property (nonatomic, copy)   NSArray *selectedModels;
@property (nonatomic, assign) NSUInteger selectedCount;

@property (nonatomic, assign) BOOL isCameraRoll;

@end

