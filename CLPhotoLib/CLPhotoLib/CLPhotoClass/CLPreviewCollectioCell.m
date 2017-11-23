//
//  CLPreviewCollectioCell.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/7.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPreviewCollectioCell.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

@interface CLPreviewCollectioCell ()

@property (nonatomic, strong) CLPreviewImageCell *imageView;
@property (nonatomic, strong) CLPreviewVideoCell *videoView;

@end

@implementation CLPreviewCollectioCell

- (CLPreviewImageCell *)imageView{
    if (!_imageView) {
        _imageView = [[CLPreviewImageCell alloc] initWithFrame:self.bounds];
        cl_WS(ws);
        [_imageView setSingleTapCallBack:^{
            if (ws.singleTapCallBack) {
                ws.singleTapCallBack();
            }
        }];
        if (_videoView) {
            [_videoView removeFromSuperview];
            _videoView = nil;
        }
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (CLPreviewVideoCell *)videoView{
    if (!_videoView) {
        _videoView = [[CLPreviewVideoCell alloc] initWithFrame:self.bounds];
        cl_WS(ws);
        [_videoView setSingleTapCallBack:^{
            if (ws.singleTapCallBack) {
                ws.singleTapCallBack();
            }
        }];
        if (_imageView) {
            [_imageView removeFromSuperview];
            _imageView = nil;
        }
        [self.contentView addSubview:_videoView];
    }
    return _videoView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _imageView.frame = self.bounds;
    _videoView.frame = self.bounds;
}

- (void)resetScale{
    [_imageView resetScale];
}

- (void)reloadGif{
    if (self.willDisplaying) {
        self.willDisplaying = NO;
        [self reload];
    } else {
        [self resumePlay];
    }
}

- (void)setModel:(CLPhotoModel *)model{
    _model = model;
    if (_model.type == CLAssetMediaTypeVideo) {
        [self.videoView loadAsset:_model.asset];
    }else{
        [self.imageView loadAsset:_model.asset];
    }
}

- (void)reload{
    if (self.showGif && _model.type == CLAssetMediaTypeGif) {
        [self.imageView loadGifImage:self.model.asset];
    } else if (self.showLivePhoto && _model.type == CLAssetMediaTypeLivePhoto) {
        [self.imageView loadLivePhoto:self.model.asset];
    }
}

- (void)resumePlay{
    if (self.model.type == CLAssetMediaTypeGif) {
        [self.imageView resumeGif];
    }
}

- (void)pausePlay{
    if (self.model.type == CLAssetMediaTypeGif) {
        [self.imageView pauseGif];
    } else if (self.model.type == CLAssetMediaTypeLivePhoto) {
        [self.imageView stopPlayLivePhoto];
    } else if (self.model.type == CLAssetMediaTypeVideo) {
        [self.videoView stopPlayVideo];
    }
}

@end


@implementation CLPreviewBaseCell

#pragma mark -
#pragma mark -- Initial Methods --
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self _setUp];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp{
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.indicator.center = self.center;
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UIActivityIndicatorView *)indicator{
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _indicator.hidesWhenStopped = YES;
        _indicator.center = self.center;
    }
    return _indicator;
}

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

- (UITapGestureRecognizer *)singleTap{
    if (!_singleTap) {
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction)];
        [self addGestureRecognizer:_singleTap];
    }
    return _singleTap;
}

- (UITapGestureRecognizer *)doubleTap{
    if (!_doubleTap) {
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        _doubleTap.numberOfTapsRequired = 2;
        [self addGestureRecognizer:_doubleTap];
    }
    return _doubleTap;
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)singleTapAction{
    if (self.singleTapCallBack) self.singleTapCallBack();
}

- (void)doubleTapAction:(UITapGestureRecognizer *)tap{
    
}

#pragma mark -
#pragma mark -- Public Methods --
- (void)loadAsset:(PHAsset *)asset{
    
}

- (void)loadGifImage:(PHAsset *)asset{
    
}

- (void)loadLivePhoto:(PHAsset *)asset{
    
}

@end


@interface CLPreviewImageCell () <UIScrollViewDelegate, PHLivePhotoViewDelegate>{
    BOOL    _loaded;
    BOOL    _isPlaying;
}
@end
@implementation CLPreviewImageCell

#pragma mark -- 重写父类方法 --
- (void)loadAsset:(PHAsset *)asset{
    if (self.asset.localIdentifier && [self.asset.localIdentifier isEqualToString:asset.localIdentifier]) {
        return;
    }
    if (self.asset && self.imageRequestID >= 0) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.asset = asset;
    if (_livePhotoView) {
        [_livePhotoView removeFromSuperview];
        _livePhotoView = nil;
    }
    [self.indicator startAnimating];
    CGFloat minWidth = MIN(self.asset.pixelWidth, self.width * [UIScreen mainScreen].scale);
    cl_weakSelf(self);
    self.imageRequestID = [CLPhotoShareManager requestCustomImageForAsset:self.asset size:CGSizeMake(minWidth, self.asset.pixelHeight/(self.asset.pixelWidth * 1.0) * minWidth) completion:^(UIImage *image, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        strongSelf.imageView.image = image;
        [strongSelf resetSubviewSize:asset];
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            [strongSelf.indicator stopAnimating];
            strongSelf->_loaded = YES;
        }
    }];
}

- (void)loadGifImage:(PHAsset *)asset{
    if (_isPlaying) {
        return;
    }
    [self.indicator startAnimating];
    cl_weakSelf(self);
    [CLPhotoShareManager requestOriginalImageDataForAsset:asset completion:^(NSData *data, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            strongSelf.imageView.image = [CLPhotoManager transformToGifImageWithData:data];
            [strongSelf resumeGif];
            [strongSelf resetSubviewSize:asset];
            [strongSelf.indicator stopAnimating];
        }
    }];
}

- (void)loadLivePhoto:(PHAsset *)asset{
    if (_isPlaying) {
        return;
    }
    if (@available(iOS 9.1, *)) {
        cl_weakSelf(self);
        [CLPhotoShareManager requestLivePhotoForAsset:asset completion:^(PHLivePhoto *lv, NSDictionary *info) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            if (lv) {
                strongSelf.livePhotoView.livePhoto = lv;
                [strongSelf resetSubviewSize:asset];
                [strongSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
            }
        }];
    }
}

#pragma mark -
#pragma mark -- Initial Methods --
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI{
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.containerView];
    [self.containerView addSubview:self.imageView];
    [self addSubview:self.indicator];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    [self.scrollView setZoomScale:1.0];
    if (_loaded) {
        [self resetSubviewSize:self.asset?:self.imageView.image];
    }
    _livePhotoView.frame = self.containerView.bounds;
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UIScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = self.bounds;
        _scrollView.maximumZoomScale = 3.0;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delaysContentTouches = NO;
    }
    return _scrollView;
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }
    return _containerView;
}

- (PHLivePhotoView *)livePhotoView{
    if (!_livePhotoView) {
        _livePhotoView = [[PHLivePhotoView alloc] initWithFrame:self.containerView.bounds];
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFit;
        _livePhotoView.delegate = self;
        [self.containerView addSubview:_livePhotoView];
    }
    return _livePhotoView;
}

- (void)resetSubviewSize:(id)obj{
    CGRect frame = CGRectZero;
    UIImage *image = self.imageView.image;
    if (!image) {
        self.containerView.frame = CGRectZero;
        return;
    }
    CGFloat imageScale = image.size.width/image.size.height;
    CGFloat screenScale = self.width/self.height;
    CGPoint point = CGPointZero;
    if (self.height > self.width) {
        if (imageScale > screenScale) {
            frame.size.width = self.width;
            frame.size.height = self.width/imageScale;
            point = self.center;
        }else{
            frame.size.width = self.width;
            frame.size.height = self.width/imageScale;
        }
    }else{
        if (imageScale > screenScale) {
            frame.size.width = self.width;
            frame.size.height = self.width/imageScale;
            point = self.center;
        }else{
            if (image.size.height < self.height) {
                frame.size.height = self.height;
                frame.size.width = self.height*imageScale;
                point = self.center;
            }else{
                CGFloat scale = 1/4.0 * self.width / self.height;
                if (imageScale > scale) {
                    frame.size.height = self.height;
                    frame.size.width = self.height*imageScale;
                    point = self.center;
                }else{
                    frame.size.width = 1/3.0 * self.width;
                    frame.size.height = 1/3.0 * self.width/imageScale;
                    point = CGPointMake(self.center.x, frame.size.height/2.0);
                }
            }
        }
    }
    self.containerView.frame = frame;
    if (!CGPointEqualToPoint(point, CGPointZero)) {
        self.containerView.center = point;
    }
    CGSize contentSize = CGSizeMake(frame.size.width, frame.size.height);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.scrollView.contentSize = contentSize;
        self.imageView.frame = self.containerView.bounds;
        [self.scrollView scrollRectToVisible:self.bounds animated:NO];
    });
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)doubleTapAction:(UITapGestureRecognizer *)tap{
    [super doubleTapAction:tap];
    UIScrollView *scrollView = self.scrollView;
    CGFloat scale = 1;
    if (scrollView.zoomScale != 3.0) {
        scale = 3;
    } else {
        scale = 1;
    }
    CGRect zoomRect = [self zoomRectForScale:scale withCenter:[tap locationInView:tap.view]];
    [scrollView zoomToRect:zoomRect animated:YES];
}

#pragma mark -
#pragma mark -- PHLivePhotoViewDelegate --
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle{
    _isPlaying = YES;
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle{
    _isPlaying = NO;
}

#pragma mark -
#pragma mark -- UIScrollViewDelegate --
- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center
{
    CGRect zoomRect;
    zoomRect.size.height = self.scrollView.frame.size.height / scale;
    zoomRect.size.width  = self.scrollView.frame.size.width  / scale;
    zoomRect.origin.x    = center.x - (zoomRect.size.width  /2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height /2.0);
    return zoomRect;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return scrollView.subviews[0];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.width > scrollView.contentSize.width) ? (scrollView.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.height > scrollView.contentSize.height) ? (scrollView.height - scrollView.contentSize.height) * 0.5 : 0.0;
    self.containerView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resumeGif];
}

#pragma mark -
#pragma mark -- Public Methods --
- (void)resetScale{
    self.scrollView.zoomScale = 1;
}

- (void)resumeGif{
    CALayer *layer = self.imageView.layer;
    if (layer.speed != 0) return;
    _isPlaying = YES;
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

- (void)pauseGif{
    CALayer *layer = self.imageView.layer;
    if (layer.speed == .0) return;
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0;
    layer.timeOffset = pausedTime;
    _isPlaying = NO;
}

- (void)stopPlayLivePhoto{
    _isPlaying = NO;
    [_livePhotoView stopPlayback];
}

@end


@implementation CLPreviewVideoCell

- (void)loadAsset:(PHAsset *)asset{
    if (self.asset && self.imageRequestID >= 0) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.asset = asset;
    [self clearPlayer];
    self.imageView.image = nil;
    self.icloudView.hidden = YES;
    [CLPhotoManager judgeAssetisInLocalAblum:asset completion:^(BOOL isInLocal) {
        if (!isInLocal) {
            [self initVideoLoadFailedFromiCloudUI];
        }
    }];
    self.playBtn.enabled = YES;
    self.imageView.hidden = NO;
    
    [self.indicator startAnimating];
    CGFloat minWidth = MIN(self.asset.pixelWidth, self.width * [UIScreen mainScreen].scale);
    cl_weakSelf(self);
    self.imageRequestID = [CLPhotoShareManager requestCustomImageForAsset:self.asset size:CGSizeMake(minWidth, self.asset.pixelHeight/(self.asset.pixelWidth * 1.0) * minWidth) completion:^(UIImage *image, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        strongSelf.imageView.image = image;
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            strongSelf.icloudView.hidden = YES;
            [strongSelf.indicator stopAnimating];
        }
    }];
}


- (AVPlayerLayer *)playLayer{
    if (!_playLayer) {
        _playLayer = [[AVPlayerLayer alloc] init];
        _playLayer.frame = self.bounds;
    }
    return _playLayer;
}

- (UIImageView *)icloudView{
    if (!_icloudView) {
        _icloudView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _icloudView.image = [UIImage imageNamedFromBundle:@"clicon_icloud_load"];
        _icloudView.hidden = YES;
        [self addSubview:_icloudView];
    }
    return _icloudView;
}

- (UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setBackgroundImage:[UIImage imageNamedFromBundle:@"btn_preview_play"] forState:UIControlStateNormal];
        _playBtn.frame = CGRectMake(0, 0, 74, 74);
        [_playBtn addTarget:self action:@selector(playBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    [self bringSubviewToFront:_playBtn];
    return _playBtn;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initUI];
    }
    return self;
}


- (void)initUI{
    [self addSubview:self.imageView];
    [self addSubview:self.icloudView];
    [self addSubview:self.playBtn];
    [self addSubview:self.indicator];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    if (@available(iOS 11.0, *)) {
        _icloudView.frame = CGRectMake(20, self.height - self.safeAreaInsets.bottom - CLToolBarHeight - 40, 20, 20);
    }else{
        _icloudView.frame = CGRectMake(20, self.height - CLToolBarHeight - 40, 20, 20);
    }
    _playBtn.center = self.center;
    _playLayer.frame = self.bounds;
}

- (void)singleTapAction{
    [super singleTapAction];
    if (_playLayer && _playLayer.player) {
        if (_playLayer.player.rate) {
            self.playBtn.hidden = NO;
            [_playLayer.player pause];
        }
    }
}

- (void)doubleTapAction:(UITapGestureRecognizer *)tap{
    [super doubleTapAction:tap];
    [self setVideoStatus];
}

- (void)setVideoStatus{
    if (!_playLayer) {
        cl_weakSelf(self);
        [CLPhotoShareManager requestVideoAssetForAsset:self.asset completion:^(AVAsset *asset, NSDictionary *info) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            if (!asset) {
                [strongSelf initVideoLoadFailedFromiCloudUI];
                return;
            }
            strongSelf.playerItem = [AVPlayerItem playerItemWithAsset:asset];
            if (!strongSelf.playerItem) {
                [strongSelf initVideoLoadFailedFromiCloudUI];
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.icloudView.hidden = YES;
                AVPlayer *player = [AVPlayer playerWithPlayerItem:strongSelf.playerItem];
                [strongSelf.layer addSublayer:strongSelf.playLayer];
                strongSelf.playLayer.player = player;
                [strongSelf switchVideoStatus];
                [strongSelf.playLayer addObserver:strongSelf forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
                [[NSNotificationCenter defaultCenter] addObserver:strongSelf selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
            });
        }];
    } else {
        [self switchVideoStatus];
    }
}

- (void)initVideoLoadFailedFromiCloudUI{
    self.icloudView.hidden = NO;
    self.playBtn.enabled = NO;
}

- (void)playBtnClick{
    [self doubleTapAction:nil];
}

- (void)switchVideoStatus{
    AVPlayer *player = self.playLayer.player;
    CMTime stop = player.currentItem.currentTime;
    CMTime duration = player.currentItem.duration;
    if (player.rate == .0) {
        self.playBtn.hidden = YES;
        if (stop.value == duration.value) {
            [player.currentItem seekToTime:CMTimeMake(0, 1)];
        }
        [player play];
    } else {
        self.playBtn.hidden = NO;
        [player pause];
    }
}

- (void)enterBackground{
    self.playBtn.hidden = NO;
    [self.playLayer.player pause];
}

- (void)playFinished:(AVPlayerItem *)item{
    [super doubleTapAction:nil];
    self.playBtn.hidden = NO;
    self.imageView.hidden = NO;
    [self.playLayer.player seekToTime:kCMTimeZero];
}

//监听获得消息
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if (self.playerItem && object == self.playerItem) {
        if ([keyPath isEqualToString:@"status"]) {
            if (self.playerItem.status == AVPlayerStatusReadyToPlay) {
                self.imageView.hidden = YES;
            }
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)stopPlayVideo{
    if (!_playLayer) {
        return;
    }
    AVPlayer *player = self.playLayer.player;
    if (player.rate != .0) {
        [player pause];
        self.playBtn.hidden = NO;
        [self clearPlayer];
    }
}

- (void)dealloc{
    [self clearPlayer];
}

- (void)clearPlayer{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_playLayer) {
        _playerItem = nil;
        _playLayer.player = nil;
        [_playLayer removeFromSuperlayer];
        [_playLayer removeObserver:self forKeyPath:@"status"];
        _playLayer = nil;
    }
}

@end
