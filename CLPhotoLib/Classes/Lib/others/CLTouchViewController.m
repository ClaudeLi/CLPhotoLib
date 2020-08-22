//
//  CLTouchViewController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/18.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLTouchViewController.h"
#import "CLPhotoModel.h"
#import "CLPhotoManager.h"
#import "CLConfig.h"
#import <PhotosUI/PhotosUI.h>

@interface CLTouchViewController ()

@end

@implementation CLTouchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:.8 alpha:.5];
    [self setupUI];
}

- (void)setupUI {
    switch (self.model.type) {
        case CLAssetMediaTypeImage:
            [self loadNormalImage];
            break;
            
        case CLAssetMediaTypeGif:
            CLAllowSelectGif ? [self loadGifImage] : [self loadNormalImage];
            break;
            
        case CLAssetMediaTypeLivePhoto:
            CLAllowSelectLivePhoto ? [self loadLivePhoto] : [self loadNormalImage];
            break;
            
        case CLAssetMediaTypeVideo:
            [self loadVideo];
            break;
            
        default:
            break;
    }
}

#pragma mark - 加载静态图
- (void)loadNormalImage {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = (CGRect){CGPointZero, self.preferredContentSize};
    [self.view addSubview:imageView];
    [CLPhotoShareManager requestCustomImageForAsset:self.model.asset size:CGSizeMake(self.preferredContentSize.width*2, self.preferredContentSize.height*2) completion:^(UIImage *image, NSDictionary *info) {
        imageView.image = image;
    }];
}

- (void)loadGifImage {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = (CGRect){CGPointZero, self.preferredContentSize};
    [self.view addSubview:imageView];
    [CLPhotoShareManager requestOriginalImageDataForAsset:self.model.asset completion:^(NSData *data, NSDictionary *info) {
        imageView.image = [CLPhotoManager transformToGifImageWithData:data];
    }];
}

- (void)loadLivePhoto {
    if (@available(iOS 9.1, *)) {
        PHLivePhotoView *lpView = [[PHLivePhotoView alloc] init];
        lpView.contentMode = UIViewContentModeScaleAspectFit;
        lpView.muted = NO;
        lpView.frame = (CGRect){CGPointZero, self.preferredContentSize};
        [self.view addSubview:lpView];
        cl_weakSelf(self);
        [CLPhotoShareManager requestLivePhotoForAsset:self.model.asset completion:^(PHLivePhoto *livePhoto, NSDictionary *info) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            lpView.livePhoto = livePhoto;
            [lpView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)loadVideo {
    AVPlayerLayer *playLayer = [[AVPlayerLayer alloc] init];
    playLayer.frame = (CGRect){CGPointZero, self.preferredContentSize};
    [self.view.layer addSublayer:playLayer];
    cl_weakSelf(self);
    [CLPhotoShareManager requestVideoPlayerItemForAsset:self.model.asset completion:^(AVPlayerItem *item, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
            playLayer.player = player;
            [player play];
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
