//
//  CLEditManager.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/16.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLEditManager.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

NSString * const CLErrorDomain = @"CLPhotoLibErrorDomain";
typedef enum {
    CLErrorDefaultCode          = -1000,
    CLErrorNotFoundVideoInfo,
    CLErrorNotFoundAudioInfo,
    CLErrorUnableToDecode,
}CLErrorCode;

@interface CLEditManager (){
    NSTimer *_timerEffect;
}

@property (nonatomic, retain) AVAssetExportSession *exportSession;

@end

@implementation CLEditManager

- (instancetype)init{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)exportEditVideoForAsset:(AVAsset *)asset
                          range:(CMTimeRange)range
                      sizeScale:(CGFloat)sizeScale
                        cutMode:(CLVideoCutMode)cutMode
                      fillColor:(UIColor *)fillColor{
    [self exportEditVideoForAsset:asset range:range sizeScale:sizeScale isDistinguishWH:YES cutMode:cutMode fillColor:fillColor];
}

- (void)exportEditVideoForAsset:(AVAsset *)asset
                          range:(CMTimeRange)range
                      sizeScale:(CGFloat)sizeScale
                isDistinguishWH:(BOOL)isDistinguishWH
                        cutMode:(CLVideoCutMode)cutMode
                      fillColor:(UIColor *)fillColor
{
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (!videoTracks.count) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:CLString(@"CLText_VideoProcessingError"), NSLocalizedDescriptionKey, CLString(@"CLText_NotGetVideoInfo"), NSLocalizedFailureReasonErrorKey, nil];
        NSError *error = [[NSError alloc] initWithDomain:CLErrorDomain code:CLErrorNotFoundVideoInfo userInfo:userInfo];
        [self onError:error];
        return;
    }
    AVAssetTrack *videoAssetTrack = [videoTracks objectAtIndex:0];
    
    // 判断视频方向
    BOOL isVideoAssetPortrait_ = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
    }
    
    // 视频显示大小
    CGSize renderSize;
    if(isVideoAssetPortrait_){
        renderSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        renderSize = videoAssetTrack.naturalSize;
    }
//    // 视频URL
//    if ([asset valueForKey:@"URL"]) {
//        return;
//    }
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    if ([compatiblePresets containsObject:AVAssetExportPreset1280x720]) {
        /*
        // 这里可以处理背景音乐
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if (!audioTracks.count) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:CLString(@"CLText_AudioProcessingError"), NSLocalizedDescriptionKey, CLString(@"CLText_NotGetAudioInfo"), NSLocalizedFailureReasonErrorKey, nil];
            NSError *error = [[NSError alloc] initWithDomain:CLErrorDomain code:CLErrorNotFoundVideoInfo userInfo:userInfo];
            [self onError:error];
            return;
        }
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // - Video track
        AVMutableCompositionTrack *videoCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
        NSError *error;
        [videoCompositionTrack insertTimeRange:range
                                       ofTrack:[videoTracks objectAtIndex:0]
                                        atTime:range.start error:&error];
        if (error) {
            [self onError:error];
            return;
        }
        // - Audio track
        AVMutableCompositionTrack *audioCompositionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioCompositionTrack insertTimeRange:range
                                       ofTrack:[audioTracks objectAtIndex:0]
                                        atTime:range.start
                                         error:&error];
        if (error) {
            [self onError:error];
            return;
        }
        */
        
        // 1. - Create AVMutableVideoCompositionInstruction
        AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        
        // 2. - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
        AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
        // 不透明度
        [videoLayerInstruction setOpacity:1.0 atTime:kCMTimeZero];
        
        // 3. - Add instructions
        mainInstruction.layerInstructions = [NSArray arrayWithObjects:videoLayerInstruction, nil];
        
        // 4. - Create AVMutableVideoComposition
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
//        mainCompositionInst.renderSize = renderSize;
        mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
        
        // 判断是否区分横竖比例
        if (!isDistinguishWH) {
            if (renderSize.width/renderSize.height >= 1.0) {
                sizeScale = sizeScale >= 1.0 ? sizeScale:1.0/sizeScale;
            }else{
                sizeScale = sizeScale < 1.0 ? sizeScale:1.0/sizeScale;
            }
        }
        // 设置输出视频尺寸大小及方向
        CGSize outputSize = renderSize;
        switch (cutMode) {
            case CLVideoCutModeScaleAspectFit:
            {
                if (renderSize.width/renderSize.height > sizeScale) {
                    outputSize.width = renderSize.width;
                    outputSize.height = renderSize.width/sizeScale;
                }else{
                    outputSize.height = renderSize.height;
                    outputSize.width = renderSize.height*sizeScale;
                }
                // 方向
                [videoLayerInstruction setTransform:videoTransform atTime:kCMTimeZero];
                [self layerWithOutputSize:outputSize
                               renderSize:renderSize
                                  cutMode:cutMode
                                fillColor:fillColor
                      mainCompositionInst:mainCompositionInst];
            }
                break;
            case CLVideoCutModeScaleAspectFill:
            {
                if (renderSize.width/renderSize.height > sizeScale) {
                    outputSize.height = renderSize.height;
                    outputSize.width = outputSize.height*sizeScale;
                    videoTransform.tx -= (renderSize.width-outputSize.width)/2.0;
                    [videoLayerInstruction setTransform:videoTransform atTime:kCMTimeZero];
                }else{
                    outputSize.width = renderSize.width;
                    outputSize.height = outputSize.width/sizeScale;
                    videoTransform.ty -= (renderSize.height-outputSize.height)/2.0;
                    [videoLayerInstruction setTransform:videoTransform atTime:kCMTimeZero];
                }
                [self layerWithOutputSize:outputSize
                               renderSize:renderSize
                                  cutMode:cutMode
                                fillColor:fillColor
                      mainCompositionInst:mainCompositionInst];
            }
                break;
            default:
            {
                [videoLayerInstruction setTransform:videoTransform atTime:kCMTimeZero];
                mainCompositionInst.renderSize = outputSize;
            }
                break;
        }
        if (MIN(outputSize.width, outputSize.height) >= 540) {
            mainCompositionInst.frameDuration = CMTimeMake(1, 25);
        }else{
            mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        }
        [self removeTimer];
        NSString *outputPath = CLVideoOutputPath();
        [self deleteFilePath:outputPath];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        // AVAssetExportPreset1280x720 压缩质量
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:asset presetName:AVAssetExportPreset1280x720];
        _exportSession.timeRange = range;
        
        NSURL *furl = [NSURL fileURLWithPath:outputPath];
        _exportSession.outputURL = furl;
        _exportSession.outputFileType = AVFileTypeMPEG4;
        
        [_exportSession setVideoComposition:mainCompositionInst];
        [_exportSession setShouldOptimizeForNetworkUse:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Progress monitor for effect
            _timerEffect = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                                            target:self
                                                          selector:@selector(handlingProgress)
                                                          userInfo:nil
                                                           repeats:YES];
        });
        cl_weakSelf(self);
        [_exportSession exportAsynchronouslyWithCompletionHandler:^{
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [strongSelf removeTimer];
            });
            switch ([strongSelf.exportSession status]) {
                case AVAssetExportSessionStatusFailed:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf onError:strongSelf.exportSession.error];
                        [strongSelf.exportSession cancelExport];
                        strongSelf.exportSession = nil;
                    });
                }
                    break;
                case AVAssetExportSessionStatusCancelled:
                {
                    [strongSelf.exportSession cancelExport];
                    strongSelf.exportSession = nil;
                }
                    break;
                default:{
                    [strongSelf.exportSession cancelExport];
                    strongSelf.exportSession = nil;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf didFinishedOutputURL:furl];
                    });
                }
                    break;
            }
        }];
    }else{
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:CLString(@"CLText_VideoProcessingError"), NSLocalizedDescriptionKey, CLString(@"CLText_UnableToDecode"), NSLocalizedFailureReasonErrorKey, nil];
        NSError *error = [[NSError alloc] initWithDomain:CLErrorDomain code:CLErrorUnableToDecode userInfo:userInfo];
        [self onError:error];
    }
}

- (void)layerWithOutputSize:(CGSize)outputSize
                 renderSize:(CGSize)renderSize
                    cutMode:(CLVideoCutMode)cutMode
                  fillColor:(UIColor *)fillColor
        mainCompositionInst:(AVMutableVideoComposition *)mainCompositionInst
{
    mainCompositionInst.renderSize = outputSize;
    // 1 - creat backgroundLayer
    //    UIImage *borderImage = [UIImage imageWithColor:fillColor rectSize:(CGRect){CGPointZero, videoSize}];
    //
    //    CALayer *backgroundLayer = [CALayer layer];
    //    [backgroundLayer setContents:(id)[borderImage CGImage]];
    //    backgroundLayer.frame = (CGRect){CGPointZero, videoSize};
    //    [backgroundLayer setMasksToBounds:YES];
    
    // 2 - creat videoLayer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.frame = (CGRect){CGPointZero, outputSize};
    parentLayer.backgroundColor = fillColor.CGColor;
    if (cutMode == CLVideoCutModeScaleAspectFit) {
        videoLayer.frame = (CGRect){
            (CGPoint){
                (outputSize.width - renderSize.width)/2.0,
                -(outputSize.height - renderSize.height)/2.0
            },
            outputSize
        };
    }else{
        videoLayer.frame = (CGRect){
            CGPointZero,
            CGSizeMake(outputSize.width, outputSize.height)
        };
        // 相当于center
        videoLayer.position = parentLayer.position;
    }
    //    [parentLayer addSublayer:backgroundLayer];
    [parentLayer addSublayer:videoLayer];
    
    // 3. creat maskLayer 放在videoLayer上面填充视频空余
    if ((outputSize.width - renderSize.width) > 0) {
        CALayer *maskLayer = [CALayer layer];
        maskLayer.backgroundColor = fillColor.CGColor;
        maskLayer.frame = (CGRect){
            (CGPoint){
                outputSize.width - (outputSize.width - renderSize.width)/2.0,
                0
            },
            (CGSize){
                (outputSize.width - renderSize.width)/2.0,
                outputSize.height
            }
        };
        [parentLayer addSublayer:maskLayer];
    }
    if ((outputSize.height - renderSize.height) > 0) {
        CALayer *maskLayer = [CALayer layer];
        maskLayer.backgroundColor = fillColor.CGColor;
        maskLayer.frame = (CGRect){
            CGPointZero,
            (CGSize){
                outputSize.width,
                (outputSize.height - renderSize.height)/2.0
            }
        };
        [parentLayer addSublayer:maskLayer];
    }
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool
                                         videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
}

- (void)deleteFilePath:(NSString *)path{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:path];
    NSError *err;
    if (exist) {
        [fm removeItemAtPath:path error:&err];
        if (err) {
            CLLog(@"file remove error, %@", err.localizedDescription);
        }
    }
}

- (void)cancelExport{
    if (_exportSession) {
        [_exportSession cancelExport];
        _exportSession = nil;
    }
}

- (void)removeTimer{
    if (_timerEffect) {
        [_timerEffect invalidate];
        _timerEffect = nil;
    }
}

- (void)handlingProgress{
    if ([self.delegate respondsToSelector:@selector(editManager:handlingProgress:)]) {
        [self.delegate editManager:self handlingProgress:self.exportSession.progress];
    }
}

- (void)onError:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(editManager:operationFailure:)]) {
        [self.delegate editManager:self operationFailure:error];
    }
}

- (void)didFinishedOutputURL:(NSURL *)outputURL{
    if ([self.delegate respondsToSelector:@selector(editManager:didFinishedOutputURL:)]) {
        [self.delegate editManager:self didFinishedOutputURL:outputURL];
    }
}

#pragma mark -
#pragma mark -- Public Class Methods --
static AVAssetImageGenerator *_generator;

+ (UIImage *)requestThumbnailImageForAVAsset:(AVAsset *)asset
                                timeBySecond:(NSTimeInterval)timeBySecond
{
    if (!asset) {
        return nil;
    }
    // 根据AVURLAsset创建AVAssetImageGenerator
    _generator =[AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    _generator.appliesPreferredTrackTransform = YES;
    _generator.requestedTimeToleranceAfter = kCMTimeZero;
    _generator.requestedTimeToleranceBefore = kCMTimeZero;
    /*截图
     * requestTime:缩略图创建时间
     * actualTime:缩略图实际生成的时间
     */
    NSError *error=nil;
    // CMTime是表示电影时间信息的结构体，第一个参数是视频第几秒，第二个参数时每秒帧数.(如果要活的某一秒的第几帧可以使用CMTimeMake方法)
    CMTime time = CMTimeMakeWithSeconds(timeBySecond, 30);
    CMTime actualTime;
    CGImageRef cgImage= [_generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    _generator = nil;
    if(error){
        CLLog(@"截取视频缩略图时发生错误，错误信息：%@",error.localizedDescription);
        CGImageRelease(cgImage);
        return nil;
    }
    UIImage *image = [UIImage imageWithCGImage:cgImage];//转化为UIImage
    CGImageRelease(cgImage);
    return image;
}

+ (void)requestThumbnailImagesForAVAsset:(AVAsset *)asset
                                interval:(NSTimeInterval)interval
                                    size:(CGSize)size
                           eachThumbnail:(void (^)(UIImage *image))eachThumbnail
                                complete:(void (^)(AVAsset *asset, NSArray<UIImage *> *images))complete
{
    NSTimeInterval duration = asset.duration.value/(asset.duration.timescale * 1.0);
    long imgCount = round(duration/interval);
    [self requestThumbnailImagesForAVAsset:asset duration:duration imageCount:imgCount interval:interval size:size eachThumbnail:eachThumbnail complete:complete];
}

+ (void)requestThumbnailImagesForAVAsset:(AVAsset *)asset
                                duration:(NSTimeInterval)duration
                              imageCount:(NSInteger)imageCount
                                interval:(NSTimeInterval)interval
                                    size:(CGSize)size
                           eachThumbnail:(void (^)(UIImage *image))eachThumbnail
                                complete:(void (^)(AVAsset *asset, NSArray<UIImage *> *images))complete
{
    [self cancelAllCGImageGeneration];
    _generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    _generator.maximumSize = size;
    _generator.appliesPreferredTrackTransform = YES;
    _generator.requestedTimeToleranceBefore = kCMTimeZero;
    _generator.requestedTimeToleranceAfter = kCMTimeZero;

    NSMutableArray *arr = [NSMutableArray array];
    NSTimeInterval imgTime = 0;
    for (int i = 0; i < imageCount; i++) {
        /*
         CMTimeMake(a,b) a当前第几帧, b每秒钟多少帧
         */
        // 这里有需要时加上0.1 是为了避免解析0s图片必定失败的问题
        CMTime time = CMTimeMake((imgTime) * asset.duration.timescale, asset.duration.timescale);
        NSValue *value = [NSValue valueWithCMTime:time];
        [arr addObject:value];
        imgTime += interval;
        if (imgTime > duration) {
            break;
        }
    }
    NSMutableArray *arrImages = [NSMutableArray array];
    __block long count = 0;
    [_generator generateCGImagesAsynchronouslyForTimes:arr
                                    completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        switch (result) {
            case AVAssetImageGeneratorSucceeded:
            {
                UIImage *img = [UIImage imageWithCGImage:image];
                if (eachThumbnail) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        eachThumbnail(img);
                    });
                }
                [arrImages addObject:img];
            }
                break;
            case AVAssetImageGeneratorFailed:
                CLLog(@"第%ld张图片解析失败", count);
                break;
            case AVAssetImageGeneratorCancelled:
                CLLog(@"取消解析视频图片");
                break;
        }
        count++;
        if (count == arr.count && complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(asset, arrImages);
            });
        }
    }];
}

+ (void)cancelAllCGImageGeneration{
    if (_generator) {
        [_generator cancelAllCGImageGeneration];
        _generator = nil;
    }
}

@end
