//
//  CLAssetModel.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    CLAssetModelMediaTypePhoto = 0,
    CLAssetModelMediaTypeLivePhoto,
    CLAssetModelMediaTypeVideo,
    CLAssetModelMediaTypeAudio
} CLAssetModelMediaType;

@class PHAsset;
@interface CLAssetModel : NSObject

@property (nonatomic, strong) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) CLAssetModelMediaType type;
@property (nonatomic, copy)   NSString *timeLength;

/// Init a photo dataModel With a asset
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(id)asset type:(CLAssetModelMediaType)type;
+ (instancetype)modelWithAsset:(id)asset type:(CLAssetModelMediaType)type timeLength:(NSString *)timeLength;

@end


@class PHFetchResult;
@interface CLAlbumModel : NSObject

@property (nonatomic, strong) NSString *name;        ///< The album name
@property (nonatomic, assign) NSInteger count;       ///< Count of photos the album contain
@property (nonatomic, strong) id result;             ///< PHFetchResult<PHAsset> or ALAssetsGroup<ALAsset>

@property (nonatomic, strong) NSArray *models;
@property (nonatomic, strong) NSArray *selectedModels;
@property (nonatomic, assign) NSUInteger selectedCount;

@end
