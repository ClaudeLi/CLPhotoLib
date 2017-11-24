//
//  CLPhotoModel.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPhotoModel.h"
#import "CLPhotoManager.h"

@implementation CLPhotoModel

+ (instancetype)modelWithAsset:(PHAsset *)asset{
    CLPhotoModel *model = [[CLPhotoModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = [CLPhotoModel transformAssetType:asset];
    return model;
}
    
+ (instancetype)modelWithAsset:(PHAsset *)asset type:(CLAssetMediaType)type{
    CLPhotoModel *model = [[CLPhotoModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(PHAsset *)asset type:(CLAssetMediaType)type duration:(CGFloat)duration{
    CLPhotoModel *model = [self modelWithAsset:asset type:type];
    model.duration = duration;
    model.timeFormat = [self timeWithFormat:duration];
    return model;
}

+ (NSString *)timeWithFormat:(CGFloat)dur{
    NSInteger duration = (NSInteger)round(dur);
    if (duration < 60) {
        return [NSString stringWithFormat:@"00:%02ld", (long)duration];
    } else if (duration < 3600) {
        NSInteger m = duration / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld", (long)m, (long)s];
    } else {
        NSInteger h = duration / 3600;
        NSInteger m = (duration % 3600) / 60;
        NSInteger s = duration % 60;
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)h, (long)m, (long)s];
    }
}
    
+ (CLAssetMediaType)transformAssetType:(PHAsset *)asset{
    switch (asset.mediaType) {
        case PHAssetMediaTypeAudio:
        return CLAssetMediaTypeAudio;
        case PHAssetMediaTypeVideo:
        return CLAssetMediaTypeVideo;
        case PHAssetMediaTypeImage:
        if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) return CLAssetMediaTypeGif;
        if (@available(iOS 9.1, *)) {
            if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive || asset.mediaSubtypes == 10) return CLAssetMediaTypeLivePhoto;
        }
        return CLAssetMediaTypeImage;
        default:
        return CLAssetMediaTypeUnknown;
    }
}

@end


@implementation CLAlbumModel

- (void)setSelectedModels:(NSArray *)selectedModels {
    _selectedModels = selectedModels;
    if (_models) {
        [self checkSelectedModels];
    }
}

- (void)checkSelectedModels {
    self.selectedCount = [CLPhotoManager checkSelcectModelInArray:_models selArray:_selectedModels];
}

@end


