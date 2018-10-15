//
//  CLPhotoManager.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/10/31.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPhotoManager.h"
#import "CLConfig.h"
#import "CLPhotoModel.h"

static NSString *sortDescriptorKey = @"modificationDate";
@implementation CLPhotoManager

+ (instancetype)shareManager{
    static CLPhotoManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (NSString *)appName{
    if (!_appName) {
        _appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!_appName) _appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
    }
    return _appName;
}

#pragma mark -
#pragma mark -- Public Object Methods --
// 获得（相册交卷/所有图片）所在的相册
- (void)getCameraRollAlbumWithSelectMode:(CLPickerSelectMode)selectMode complete:(void (^)(CLAlbumModel *albumModel))complete{
    if (complete) {
        complete([self getCameraRollAlbumWithSelectMode:selectMode]);
    }
}

// 获得 所有相册/相册数组
- (void)getAlbumListWithSelectMode:(CLPickerSelectMode)selectMode completion:(void (^)(NSArray<CLAlbumModel *> *models))completion{
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (selectMode == CLPickerSelectModeAllowImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (selectMode == CLPickerSelectModeAllowVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortDescriptorKey ascending:self.sortAscending]];
    // 获取所有智能相册
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *streamAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *userAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[smartAlbums, streamAlbums, userAlbums, syncedAlbums, sharedAlbums];
    /**
     PHAssetCollectionSubtypeAlbumRegular         = 2,///
     PHAssetCollectionSubtypeAlbumSyncedEvent     = 3,////
     PHAssetCollectionSubtypeAlbumSyncedFaces     = 4,////面孔
     PHAssetCollectionSubtypeAlbumSyncedAlbum     = 5,////
     PHAssetCollectionSubtypeAlbumImported        = 6,////
     
     // PHAssetCollectionTypeAlbum shared subtypes
     PHAssetCollectionSubtypeAlbumMyPhotoStream   = 100,///
     PHAssetCollectionSubtypeAlbumCloudShared     = 101,///
     
     // PHAssetCollectionTypeSmartAlbum subtypes        //// collection.localizedTitle
     PHAssetCollectionSubtypeSmartAlbumGeneric    = 200,///
     PHAssetCollectionSubtypeSmartAlbumPanoramas  = 201,///全景照片
     PHAssetCollectionSubtypeSmartAlbumVideos     = 202,///视频
     PHAssetCollectionSubtypeSmartAlbumFavorites  = 203,///个人收藏
     PHAssetCollectionSubtypeSmartAlbumTimelapses = 204,///延时摄影
     PHAssetCollectionSubtypeSmartAlbumAllHidden  = 205,/// 已隐藏
     PHAssetCollectionSubtypeSmartAlbumRecentlyAdded = 206,///最近添加
     PHAssetCollectionSubtypeSmartAlbumBursts     = 207,///连拍快照
     PHAssetCollectionSubtypeSmartAlbumSlomoVideos = 208,///慢动作
     PHAssetCollectionSubtypeSmartAlbumUserLibrary = 209,///所有照片
     PHAssetCollectionSubtypeSmartAlbumSelfPortraits NS_AVAILABLE_IOS(9_0) = 210,///自拍
     PHAssetCollectionSubtypeSmartAlbumScreenshots NS_AVAILABLE_IOS(9_0) = 211,///屏幕快照
     = 1000000201///最近删除知道值为（1000000201）但没找到对应的TypedefName
     // Used for fetching, if you don't care about the exact subtype
     PHAssetCollectionSubtypeAny = NSIntegerMax /////所有类型
     */
    NSMutableArray *albumArray = [NSMutableArray array];
    for (PHFetchResult<PHAssetCollection *> *album in allAlbums) {
        [album enumerateObjectsUsingBlock:^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
            // 过滤PHCollectionList对象
            if (![collection isKindOfClass:PHAssetCollection.class]){
                return;
            }
            // 过滤最近删除
            if (collection.assetCollectionSubtype > 215){
                return;
            }
            // 获取相册内asset result
            PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (!result.count) return;
            if (collection.assetCollectionSubtype == 209) {
                CLAlbumModel *model = [self getAlbumModeWithTitle:collection.localizedTitle result:result selectMode:selectMode];
                model.isCameraRoll = YES;
                [albumArray insertObject:model atIndex:0];
            } else {
                [albumArray addObject:[self getAlbumModeWithTitle:collection.localizedTitle result:result selectMode:selectMode]];
            }
        }];
    }
    if (completion && albumArray.count > 0) completion(albumArray);
}

- (void)requestImagesWithModelArray:(NSMutableArray<CLPhotoModel *> *)modelArray isOriginal:(BOOL)isOriginal completion:(void (^)(NSArray<UIImage *> *photos, NSArray *assets))completion{
    __block NSMutableArray *photos = [NSMutableArray arrayWithCapacity:modelArray.count];
    __block NSMutableArray *assets = [NSMutableArray arrayWithCapacity:modelArray.count];
    for (int i = 0; i < modelArray.count; i++) {
        [photos addObject:@1];
        [assets addObject:@1];
    }
    for (int i = 0; i < modelArray.count; i++) {
        CLPhotoModel *model = modelArray[i];
        [self requestImageForModel:model isOriginal:isOriginal completion:^(UIImage *image, NSDictionary *info) {
            if ([[info objectForKey:PHImageResultIsDegradedKey] boolValue]) return;
            if (image) {
                [photos replaceObjectAtIndex:i withObject:image];
                [assets replaceObjectAtIndex:i withObject:model.asset];
            }
            for (id item in photos) {
                if ([item isKindOfClass:[NSNumber class]]) return;
            }
            if (completion) {
                completion(photos, assets);
            }
        }];
    }
}

- (void)requestLivePhotoForAsset:(PHAsset *)asset completion:(void (^)(PHLivePhoto *livePhoto, NSDictionary *info))completion{
    PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc] init];
    option.version = PHImageRequestOptionsVersionCurrent;
    option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    option.networkAccessAllowed = YES;
    [[PHCachingImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey];
        if (downloadFinined && completion) completion(livePhoto, info);
    }];
}

// 获取图片
- (PHImageRequestID)requestCustomImageForAsset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage *image, NSDictionary *info))completion{
    return [self requestImageForAsset:asset size:size resizeMode:PHImageRequestOptionsResizeModeFast completion:completion];
}

// 获取原图
- (PHImageRequestID)requestOriginalImageForAsset:(PHAsset *)asset completion:(void (^)(UIImage *image, NSDictionary *))completion{
    return [self requestImageForAsset:asset size:CGSizeMake(asset.pixelWidth, asset.pixelHeight) resizeMode:PHImageRequestOptionsResizeModeNone completion:completion];
}

- (PHImageRequestID)requestImageForAsset:(PHAsset *)asset size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void (^)(UIImage *image, NSDictionary *info))completion{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    /**
     resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。
     deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
     这个属性只有在 synchronous 为 true 时有效。
     */
    option.resizeMode = resizeMode;//控制照片尺寸
//        option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;//控制照片质量
    option.networkAccessAllowed = YES;
    
    /*
     info字典提供请求状态信息:
     PHImageResultIsInCloudKey：图像是否必须从iCloud请求
     PHImageResultIsDegradedKey：当前UIImage是否是低质量的，这个可以实现给用户先显示一个预览图
     PHImageResultRequestIDKey和PHImageCancelledKey：请求ID以及请求是否已经被取消
     PHImageErrorKey：如果没有图像，字典内的错误信息
     */
    return [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
        BOOL downloadFinined = ![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey];
        // 不要该判断，即如果该图片在iCloud上时候，会先显示一张模糊的预览图，待加载完毕后会显示高清图
        // && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]
        if (downloadFinined && completion) {
            completion(image, info);
        }
    }];
}

- (void)requestVideoPlayerItemForAsset:(PHAsset *)asset completion:(void (^)(AVPlayerItem *item, NSDictionary *info))completion
{
    [[PHCachingImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
        if (completion) completion(playerItem, info);
    }];
}

- (void)requestVideoAssetForAsset:(PHAsset *)asset completion:(void (^)(AVAsset *asset, NSDictionary *info))completion{
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (completion) completion(asset, info);
    }];
}


#pragma mark -
#pragma mark -- Private Object Methods --
- (void)requestImageForModel:(CLPhotoModel *)model isOriginal:(BOOL)isOriginal completion:(void (^)(UIImage *image, NSDictionary *info))completion{
    if (model.type == CLAssetMediaTypeGif && self.allowSelectGif) {
        [self requestOriginalImageDataForAsset:model.asset completion:^(NSData *data, NSDictionary *info) {
            if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
                UIImage *image = [CLPhotoManager transformToGifImageWithData:data];
                if (completion) {
                    completion(image, info);
                }
            }
        }];
    } else {
        if (isOriginal) {
            [self requestOriginalImageForAsset:model.asset completion:completion];
        } else {
            if (model.asset.pixelWidth < CLMinSize.width || model.asset.pixelHeight < CLMinSize.height) {
                [self requestOriginalImageForAsset:model.asset completion:completion];
            }else{
                if (model.asset.pixelWidth < model.asset.pixelHeight) {
                    CGSize size = CGSizeMake(CLMinSize.width, CLMinSize.width/model.asset.pixelWidth * model.asset.pixelHeight);
                    [self requestCustomImageForAsset:model.asset size:size completion:completion];
                }else{
                    CGSize size = CGSizeMake(CLMinSize.height/model.asset.pixelHeight * model.asset.pixelWidth, CLMinSize.height);
                    [self requestCustomImageForAsset:model.asset size:size completion:completion];
                }
            }
        }
    }
}

- (void)requestOriginalImageDataForAsset:(PHAsset *)asset completion:(void (^)(NSData *data, NSDictionary *info))completion{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
    option.networkAccessAllowed = YES;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && imageData) {
            if (completion) completion(imageData, info);
        }
    }];
}

// 获得（相册交卷/所有图片）所在的相册
- (CLAlbumModel *)getCameraRollAlbumWithSelectMode:(CLPickerSelectMode)selectMode{
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (selectMode == CLPickerSelectModeAllowImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (selectMode == CLPickerSelectModeAllowVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
    
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:sortDescriptorKey ascending:self.sortAscending]];
    
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    __block CLAlbumModel *model;
    [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *  _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        //获取相册内asset result
        if (collection.assetCollectionSubtype == 209) {
            PHFetchResult<PHAsset *> *result = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            model = [self getAlbumModeWithTitle:collection.localizedTitle result:result selectMode:selectMode];
            model.isCameraRoll = YES;
        }
    }];
    return model;
}

// 获取相册model
- (CLAlbumModel *)getAlbumModeWithTitle:(NSString *)title result:(PHFetchResult<PHAsset *> *)result selectMode:(CLPickerSelectMode)selectMode{
    CLAlbumModel *model = [[CLAlbumModel alloc] init];
    model.title = title;
    model.count = result.count;
    model.result = result;
    if (CLSortAscending) {
        model.firstAsset = result.lastObject;
    } else {
        model.firstAsset = result.firstObject;
    }
    // 为了获取所有asset gif设置为yes
    model.models = [self getPhotoInResult:result selectMode:selectMode limitCount:NSIntegerMax];
    return model;
}

- (NSArray<CLPhotoModel *> *)getPhotoInResult:(PHFetchResult<PHAsset *> *)result selectMode:(CLPickerSelectMode)selectMode limitCount:(NSInteger)limitCount{
    NSMutableArray<CLPhotoModel *> *arrModel = [NSMutableArray array];
    __block NSInteger count = 1;
    [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CLAssetMediaType type = [self getPHAssetType:obj];
        
        if (type == CLAssetMediaTypeImage && selectMode == CLPickerSelectModeAllowVideo) return;
        if (type == CLAssetMediaTypeGif && selectMode == CLPickerSelectModeAllowVideo) return;
        if (type == CLAssetMediaTypeLivePhoto && selectMode == CLPickerSelectModeAllowVideo) return;
        if (type == CLAssetMediaTypeVideo && selectMode == CLPickerSelectModeAllowImage) return;
        
        if (count == limitCount) {
            *stop = YES;
        }
        
        CGFloat duration = [CLPhotoManager getDuration:obj];
        [arrModel addObject:[CLPhotoModel modelWithAsset:obj type:type duration:duration]];
        count++;
    }];
    return arrModel;
}

// 系统mediatype 转换为 自定义type
- (CLAssetMediaType)getPHAssetType:(PHAsset *)asset{
    return [CLPhotoModel transformAssetType:asset];
}

#pragma mark -
#pragma mark -- Private Class Methods --
+ (void)judgeAssetisInLocalAblum:(PHAsset *)asset completion:(void (^)(BOOL isInLocal))completion
{
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.networkAccessAllowed = NO;
    option.synchronous = YES;
    
    __block BOOL isInLocalAblum = YES;
    
    [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        isInLocalAblum = imageData ? YES : NO;
        if (completion) {
            completion(isInLocalAblum);
        }
    }];
}

+ (UIImage *)transformToGifImageWithData:(NSData *)data
{
    return [self sd_animatedGIFWithData:data];
}

+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    size_t count = CGImageSourceGetCount(source);
    
    UIImage *animatedImage;
    
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        
        NSTimeInterval duration = 0.0f;
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            duration += [self sd_frameDurationAtIndex:i source:source];
            UIImage *oneImg = [UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            if (oneImg) {
                [images addObject:oneImg];
            }
            CGImageRelease(image);
        }
        
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    
    CFRelease(source);
    
    return animatedImage;
}

+ (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (CGFloat)getDuration:(PHAsset *)asset{
    if (asset.mediaType != PHAssetMediaTypeVideo) return 0;
    return floorf(asset.duration * 100)/100.0;
}

+ (NSString *)transformDataLength:(NSInteger)dataLength {
    NSString *bytes = @"";
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%ldB",(long)dataLength];
    }
    return bytes;
}

#pragma mark -
#pragma mark -- Public Class Methods --
+ (void)getPhotosBytesWithArray:(NSArray<CLPhotoModel *> *)photos completion:(void (^)(NSString *photosBytes))completion{
    __block NSInteger dataLength = 0;
    __block NSInteger count = photos.count;
    
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < photos.count; i++) {
        CLPhotoModel *model = photos[i];
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                dataLength += imageData.length;
                count--;
                if (count <= 0) {
                    if (completion) {
                        completion([strongSelf transformDataLength:dataLength]);
                    }
                }
            }
        }];
    }
}

+ (NSArray *)getLocalIdentifierArrayWithArray:(NSArray<CLPhotoModel *> *)array{
    NSMutableArray *identifiers = [NSMutableArray array];
    for (CLPhotoModel *model in array) {
        [identifiers addObject:model.asset.localIdentifier];
    }
    return identifiers.copy;
}

+ (BOOL)checkSelcectedWithModel:(CLPhotoModel *)model identifiers:(NSArray *)identifiers{
    return [identifiers containsObject:model.asset.localIdentifier];
}

+ (NSInteger)checkSelcectModelInArray:(NSArray<CLPhotoModel *> *)dataArray selArray:(NSArray<CLPhotoModel *> *)selArray{
    NSInteger i = 0;
    NSArray *selIdentifiers = [self getLocalIdentifierArrayWithArray:selArray];
    for (CLPhotoModel *model in dataArray) {
        if ([self checkSelcectedWithModel:model identifiers:selIdentifiers]) {
            model.isSelected = YES;
            i++;
        } else {
            model.isSelected = NO;
        }
    }
    return i;
}


#pragma mark - 保存图片到系统相册
+ (void)saveImageToAblum:(UIImage *)image completion:(void (^)(BOOL, PHAsset *))completion{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (completion) completion(NO, nil);
    } else if (status == PHAuthorizationStatusRestricted) {
        if (completion) completion(NO, nil);
    } else {
        __block PHObjectPlaceholder *placeholderAsset=nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                if (completion) completion(NO, nil);
                return;
            }
            PHAsset *asset = [self getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
            PHAssetCollection *desCollection = [self getDestinationCollection];
            if (!desCollection) completion(NO, nil);
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:desCollection] addAssets:@[asset]];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (completion) completion(success, asset);
            }];
        }];
    }
}

+ (void)saveVideoToAblum:(NSURL *)url completion:(void (^)(BOOL, PHAsset *))completion{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied) {
        if (completion) completion(NO, nil);
    } else if (status == PHAuthorizationStatusRestricted) {
        if (completion) completion(NO, nil);
    } else {
        __block PHObjectPlaceholder *placeholderAsset=nil;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *newAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
            placeholderAsset = newAssetRequest.placeholderForCreatedAsset;
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                if (completion) completion(NO, nil);
                return;
            }
            PHAsset *asset = [self getAssetFromlocalIdentifier:placeholderAsset.localIdentifier];
            PHAssetCollection *desCollection = [self getDestinationCollection];
            if (!desCollection) completion(NO, nil);
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                if (asset) {
                    [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:desCollection] addAssets:@[asset]];
                }
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (completion) completion(success, asset);
            }];
        }];
    }
}

+ (PHAsset *)getAssetFromlocalIdentifier:(NSString *)localIdentifier{
    if(localIdentifier == nil){
        CLLog(@"Cannot get asset from localID because it is nil");
        return nil;
    }
    PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    if(result.count){
        return result[0];
    }
    return nil;
}

//获取自定义相册
+ (PHAssetCollection *)getDestinationCollection{
    // 找是否已经创建自定义相册
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        if ([collection.localizedTitle isEqualToString:CLAppName]) {
            return collection;
        }
    }
    // 新建自定义相册
    __block NSString *collectionId = nil;
    NSError *error = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:CLAppName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    if (error) {
        CLLog(@"Creat '%@' Ablum Error：%@", CLAppName, error.localizedDescription);
        return nil;
    }
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].lastObject;
}


@end
