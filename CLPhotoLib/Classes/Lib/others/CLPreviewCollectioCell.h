//
//  CLPreviewCollectioCell.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/7.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>

@class CLPhotoModel;
@class CLPreviewImageCell;
@class CLPreviewVideoCell;
@interface CLPreviewCollectioCell : UICollectionViewCell

@property (nonatomic, assign) BOOL showGif;
@property (nonatomic, assign) BOOL showLivePhoto;

@property (nonatomic, strong) CLPhotoModel *model;
@property (nonatomic, assign) BOOL willDisplaying;
@property (nonatomic, copy)   void (^singleTapCallBack)(void);

- (void)reloadGif;

- (void)pausePlay:(BOOL)stop;

- (void)resetScale;

@end

@interface CLPreviewBaseCell : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) PHImageRequestID imageRequestID;
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic, copy)   void (^singleTapCallBack)(void);

- (void)singleTapAction;

- (void)doubleTapAction:(UITapGestureRecognizer *)tap;

- (void)loadAsset:(PHAsset *)asset;

- (void)loadGifImage:(PHAsset *)asset;

- (void)loadLivePhoto:(PHAsset *)asset;

@end

@interface CLPreviewImageCell : CLPreviewBaseCell

@property (nonatomic, strong) PHLivePhotoView   *livePhotoView API_AVAILABLE(ios(9.1));
@property (nonatomic, strong) UIView            *containerView;
@property (nonatomic, strong) UIScrollView      *scrollView;

- (void)resetScale;

- (void)resumeGif;

- (void)pauseGif;

- (void)stopPlayLivePhoto;

@end

@interface CLPreviewVideoCell : CLPreviewBaseCell

@property (nonatomic, strong) AVPlayerLayer *playLayer;
@property (nonatomic, strong) AVPlayerItem  *playerItem;
@property (nonatomic, strong) UIImageView   *icloudView;
@property (nonatomic, strong) UIButton      *playBtn;

- (void)stopPlayVideo:(BOOL)stop;

@end
