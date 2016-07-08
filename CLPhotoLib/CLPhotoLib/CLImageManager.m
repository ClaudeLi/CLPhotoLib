//
//  CLImageManager.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "CLImageManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "CLAssetModel.h"
#import "CLPhotoLib.h"

@interface CLImageManager ()
@property (nonatomic, strong) ALAssetsLibrary *assetLibrary;
@end

@implementation CLImageManager

static CGSize AssetGridThumbnailSize;
static CGFloat CLScreenScale;

+ (instancetype)manager {
    static CLImageManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.cachingImageManager = [[PHCachingImageManager alloc] init];
        manager.cachingImageManager.allowsCachingHighQualityImages = NO;
        manager.minSideSize = CGSizeMake(750, 750);
        // 测试发现，如果scale在plus真机上取到3.0，内存会增大特别多。故这里写死成2.0
        CLScreenScale = 2.0;
        CGFloat itemWH = (CLScreenWidth - 6) / 3;
        AssetGridThumbnailSize = CGSizeMake(itemWH * CLScreenScale, itemWH * CLScreenScale);
    });
    return manager;
}

- (void)setMinSideSize:(CGSize)minSideSize{
    _minSideSize = minSideSize;
}

- (void)setListCount:(NSInteger)listCount{
    _listCount = listCount;
    int itemWH = (CLScreenWidth - 2*listCount) / listCount;
    AssetGridThumbnailSize = CGSizeMake(itemWH * CLScreenScale, itemWH * CLScreenScale);
}

- (ALAssetsLibrary *)assetLibrary {
    if (_assetLibrary == nil) _assetLibrary = [[ALAssetsLibrary alloc] init];
    return _assetLibrary;
}

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized {
    if (iOS8Later) {
        if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) return YES;
    } else {
        if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) return YES;
    }
    return NO;
}

#pragma mark - Get Album

/// Get 获得相机胶卷/所有照片
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(CLAlbumModel *))completion{
    __block CLAlbumModel *model;
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                                    PHAssetMediaTypeVideo];
        
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] || [collection.localizedTitle isEqualToString:@"相机胶卷"] ||  [collection.localizedTitle isEqualToString:@"所有照片"] || [collection.localizedTitle isEqualToString:@"All Photos"]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                model = [self modelWithResult:fetchResult name:collection.localizedTitle];
                if (completion) completion(model);
                break;
            }
        }
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"] || [name isEqualToString:@"所有照片"] || [name isEqualToString:@"All Photos"]) {
                model = [self modelWithResult:group name:name];
                if (completion) completion(model);
                *stop = YES;
            }
        } failureBlock:nil];
    }
}

/// Get Album 获得相册/相册数组
- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<CLAlbumModel *> *))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                                    PHAssetMediaTypeVideo];

        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
        
        PHAssetCollectionSubtype smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumVideos;
        // For iOS 9, We need to show ScreenShots Album && SelfPortraits Album
        if (iOS9Later) {
            smartAlbumSubtype = PHAssetCollectionSubtypeSmartAlbumUserLibrary | PHAssetCollectionSubtypeSmartAlbumRecentlyAdded | PHAssetCollectionSubtypeSmartAlbumScreenshots | PHAssetCollectionSubtypeSmartAlbumSelfPortraits | PHAssetCollectionSubtypeSmartAlbumVideos;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:smartAlbumSubtype options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] || [collection.localizedTitle isEqualToString:@"相机胶卷"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        
        PHFetchResult *albums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular | PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        for (PHAssetCollection *collection in albums) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            if ([collection.localizedTitle isEqualToString:@"My Photo Stream"] || [collection.localizedTitle isEqualToString:@"我的照片流"]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
            }
        }
        if (completion && albumArr.count > 0) completion(albumArr);
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([name isEqualToString:@"Camera Roll"] || [name isEqualToString:@"相机胶卷"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:1];
            } else {
                [albumArr addObject:[self modelWithResult:group name:name]];
            }
        } failureBlock:nil];
    }
}

#pragma mark - Get Assets

/// Get Assets 获得照片数组
- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<CLAssetModel *> *))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAsset *asset = (PHAsset *)obj;
            CLAssetModelMediaType type = CLAssetModelMediaTypePhoto;
            if (asset.mediaType == PHAssetMediaTypeVideo)      type = CLAssetModelMediaTypeVideo;
            else if (asset.mediaType == PHAssetMediaTypeAudio) type = CLAssetModelMediaTypeAudio;
            else if (asset.mediaType == PHAssetMediaTypeImage) {
                if (iOS9_1Later) {
                    // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = CLAssetModelMediaTypeLivePhoto;
                }
            }
            if (!allowPickingVideo && type == CLAssetModelMediaTypeVideo) return;
            if (!allowPickingImage && type == CLAssetModelMediaTypePhoto) return;
            
            NSString *timeLength = type == CLAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
            timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
            [photoArr addObject:[CLAssetModel modelWithAsset:asset type:type timeLength:timeLength]];
        }];
        if (completion) completion(photoArr);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop)  {
            if (result == nil) {
                if (completion) completion(photoArr);
            }
            CLAssetModelMediaType type = CLAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                [photoArr addObject:[CLAssetModel modelWithAsset:result type:type]];
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = CLAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                [photoArr addObject:[CLAssetModel modelWithAsset:result type:type timeLength:timeLength]];
            } else {
                [photoArr addObject:[CLAssetModel modelWithAsset:result type:type]];
            }
        };
        if (self.sortAscendingByModificationDate) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        } else {
            [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (resultBlock) { resultBlock(result,index,stop); }
            }];
        }
    }
}

///  Get asset at index 获得下标为index的单个照片
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(CLAssetModel *))completion {
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        PHAsset *asset = fetchResult[index];
        
        CLAssetModelMediaType type = CLAssetModelMediaTypePhoto;
        if (asset.mediaType == PHAssetMediaTypeVideo)      type = CLAssetModelMediaTypeVideo;
        else if (asset.mediaType == PHAssetMediaTypeAudio) type = CLAssetModelMediaTypeAudio;
        else if (asset.mediaType == PHAssetMediaTypeImage) {
            if (iOS9_1Later) {
                // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = CLAssetModelMediaTypeLivePhoto;
            }
        }
        NSString *timeLength = type == CLAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        CLAssetModel *model = [CLAssetModel modelWithAsset:asset type:type timeLength:timeLength];
        if (completion) completion(model);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [group enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            CLAssetModel *model;
            CLAssetModelMediaType type = CLAssetModelMediaTypePhoto;
            if (!allowPickingVideo){
                model = [CLAssetModel modelWithAsset:result type:type];
                if (completion) completion(model);
                return;
            }
            /// Allow picking video
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                type = CLAssetModelMediaTypeVideo;
                NSTimeInterval duration = [[result valueForProperty:ALAssetPropertyDuration] integerValue];
                NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
                timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
                model = [CLAssetModel modelWithAsset:result type:type timeLength:timeLength];
            } else {
                model = [CLAssetModel modelWithAsset:result type:type];
            }
            if (completion) completion(model);
        }];
    }
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        CLAssetModel *model = photos[i];
        if ([model.asset isKindOfClass:[PHAsset class]]) {
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if (model.type != CLAssetModelMediaTypeVideo) dataLength += imageData.length;
                assetCount ++;
                if (assetCount >= photos.count) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    if (completion) completion(bytes);
                }
            }];
        } else if ([model.asset isKindOfClass:[ALAsset class]]) {
            ALAssetRepresentation *representation = [model.asset defaultRepresentation];
            if (model.type != CLAssetModelMediaTypeVideo) dataLength += (NSInteger)representation.size;
            if (i >= photos.count - 1) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion) completion(bytes);
            }
        }
    }
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

#pragma mark - Get Photo

/// Get photo 获得照片本身
- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    CGFloat fullScreenWidth = CLScreenWidth;
    if (fullScreenWidth > _photoPreviewMaxWidth) {
        fullScreenWidth = _photoPreviewMaxWidth;
    }
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion];
}

- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        CGSize imageSize;
        if (photoWidth < CLScreenWidth && photoWidth < _photoPreviewMaxWidth) {
            imageSize = AssetGridThumbnailSize;
        } else {
            PHAsset *phAsset = (PHAsset *)asset;
            imageSize = [UIImage getSizeWithImageSize:CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight) toSize:_minSideSize];
        }
        // 修复获取图片时出现的瞬间内存过高问题
        // 下面两行代码，来自hsjcom，他的github是：https://github.com/hsjcom 表示感谢
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [UIImage fixOrientation:result isRotate:self.shouldFixOrientation];
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result) {
                PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
                option.networkAccessAllowed = YES;
                option.resizeMode = PHImageRequestOptionsResizeModeFast;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:0.3];
                    resultImage = [UIImage scaleImage:resultImage toSize:imageSize];
                    if (resultImage) {
                        resultImage = [UIImage fixOrientation:resultImage isRotate:self.shouldFixOrientation];
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
        return imageRequestID;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            CGImageRef thumbnailImageRef = alAsset.thumbnail;
            UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:2.0 orientation:UIImageOrientationUp];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(thumbnailImage,nil,YES);
                
                if (photoWidth == CLScreenWidth || photoWidth == _photoPreviewMaxWidth) {
                    dispatch_async(dispatch_get_global_queue(0,0), ^{
                        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
                        CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                        UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:2.0 orientation:UIImageOrientationUp];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (completion) completion(fullScrennImage,nil,NO);
                        });
                    });
                }
            });
        });
    }
    return 0;
}

/// Get postImage / 获取封面图
- (void)getPostImageWithAlbumModel:(CLAlbumModel *)model completion:(void (^)(UIImage *))completion {
    if (iOS8Later) {
        id asset = [model.result lastObject];
        if (!self.sortAscendingByModificationDate) {
            asset = [model.result firstObject];
        }
        [[CLImageManager manager] getPhotoWithAsset:asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completion) completion(photo);
        }];
    } else {
        ALAssetsGroup *group = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:group.posterImage];
        if (completion) completion(postImage);
    }
}

/// Get Original Photo / 获取原图
- (void)getOriginalPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                result = [UIImage fixOrientation:result isRotate:self.shouldFixOrientation];
                if (completion) completion(result,info);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            CGImageRef originalImageRef = [assetRep fullResolutionImage];
            UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:1.0 orientation:UIImageOrientationUp];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(originalImage,nil);
            });
        });
    }
}

#pragma mark - Save photo
- (void)savePhotoWithImage:(UIImage *)image completion:(void (^)())completion {
    NSData *data = UIImageJPEGRepresentation(image, 0.9);
    if (iOS9Later) { // 这里有坑... iOS8系统下这个方法保存图片会失败
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
            options.shouldMoveFile = YES;
            [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (success && completion) {
                    completion();
                } else if (error) {
                    NSLog(@"保存照片出错:%@",error.localizedDescription);
                }
            });
        }];
    } else {
        [self.assetLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:[self orientationFromImage:image] completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"保存图片失败:%@",error.localizedDescription);
            } else {
                if (completion) {
                    completion();
                }
            }
        }];
    }
}

#pragma mark - Get Video
/// Get Video / 获取视频
- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion) completion(playerItem,info);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem) completion(playerItem,nil);
    }
}

#pragma mark - Export video

/// Export Video / 导出视频，暂仅仅支持iOS8.0+
- (void)getVideoOutputPathWithAsset:(id)asset completion:(void (^)(NSString *outputPath))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            // NSLog(@"Info:\n%@",info);
            AVURLAsset* myAsset = (AVURLAsset*)avasset;
            // NSLog(@"AVAsset URL: %@",myAsset.URL);
            
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:myAsset];
            // NSLog(@"%@",compatiblePresets);
            
            if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:myAsset presetName:AVAssetExportPresetMediumQuality];
                NSDateFormatter *formater = [[NSDateFormatter alloc] init];
                [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
                NSString *outputPath = [NSHomeDirectory() stringByAppendingFormat:@"/tmp/output-%@.mp4", [formater stringFromDate:[NSDate date]]];
                NSLog(@"video outputPath = %@",outputPath);
                
                exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
                exportSession.outputFileType = AVFileTypeMPEG4;
                exportSession.shouldOptimizeForNetworkUse = YES;
                [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
                    switch (exportSession.status) {
                        case AVAssetExportSessionStatusUnknown:
                            NSLog(@"AVAssetExportSessionStatusUnknown"); break;
                        case AVAssetExportSessionStatusWaiting:
                            NSLog(@"AVAssetExportSessionStatusWaiting"); break;
                        case AVAssetExportSessionStatusExporting:
                            NSLog(@"AVAssetExportSessionStatusExporting"); break;
                        case AVAssetExportSessionStatusCompleted:
                            NSLog(@"AVAssetExportSessionStatusCompleted");
                            if (completion) {
                                completion(outputPath);
                            }
                            break;
                        case AVAssetExportSessionStatusFailed:
                            NSLog(@"AVAssetExportSessionStatusFailed"); break;
                        default: break;
                    }
                }];
            }
        }];
    } else {
        NSLog(@"iOS8以前的系统，导出视频代码暂未更新...");
    }
}

/// Judge is a assets array contain the asset 判断一个assets数组是否包含这个asset
- (BOOL)isAssetsArray:(NSArray *)assets containAsset:(id)asset {
    if (iOS8Later) {
        return [assets containsObject:asset];
    } else {
        NSMutableArray *selectedAssetUrls = [NSMutableArray array];
        for (ALAsset *asset_item in assets) {
            [selectedAssetUrls addObject:[asset_item valueForProperty:ALAssetPropertyURLs]];
        }
        return [selectedAssetUrls containsObject:[asset valueForProperty:ALAssetPropertyURLs]];
    }
}

- (NSString *)getAssetIdentifier:(id)asset {
    if (iOS8Later) {
        PHAsset *phAsset = (PHAsset *)asset;
        return phAsset.localIdentifier;
    } else {
        ALAsset *alAsset = (ALAsset *)asset;
        NSURL *assetUrl = [alAsset valueForProperty:ALAssetPropertyAssetURL];
        return assetUrl.absoluteString;
    }
}

#pragma mark - Private Method

- (CLAlbumModel *)modelWithResult:(id)result name:(NSString *)name{
    CLAlbumModel *model = [[CLAlbumModel alloc] init];
    model.result = result;
    model.name = [self getNewAlbumName:name];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        model.count = fetchResult.count;
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        model.count = [group numberOfAssets];
    }
    return model;
}

- (NSString *)getNewAlbumName:(NSString *)name {
    //    if (iOS8Later) {
    //        NSString *newName;
    //        if ([name rangeOfString:@"Roll"].location != NSNotFound)         newName = @"相机胶卷";
    //        else if ([name rangeOfString:@"Stream"].location != NSNotFound)  newName = @"我的照片流";
    //        else if ([name rangeOfString:@"Added"].location != NSNotFound)   newName = @"最近添加";
    //        else if ([name rangeOfString:@"Selfies"].location != NSNotFound) newName = @"自拍";
    //        else if ([name rangeOfString:@"shots"].location != NSNotFound)   newName = @"截屏";
    //        else if ([name rangeOfString:@"Videos"].location != NSNotFound)  newName = @"视频";
    //        else if ([name rangeOfString:@"Panoramas"].location != NSNotFound)  newName = @"全景照片";
    //        else if ([name rangeOfString:@"Favorites"].location != NSNotFound)  newName = @"个人收藏";
    //        else newName = name;
    //        return newName;
    //    } else {
    //    }
    return name;
}

- (ALAssetOrientation)orientationFromImage:(UIImage *)image {
    NSInteger orientation = image.imageOrientation;
    return orientation;
}


@end
