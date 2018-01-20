//
//  CLPickerRootController.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/**
 选择模式
 - CLPickerSelectModeMixDisplay: 混合显示
 - CLPickerSelectModeAllowImage: 只显示图片
 - CLPickerSelectModeAllowVideo: 只显示视频
 */
typedef NS_ENUM(NSInteger, CLPickerSelectMode) {
    CLPickerSelectModeMixDisplay,
    CLPickerSelectModeAllowImage,
    CLPickerSelectModeAllowVideo,
};

typedef void(^CLPickingPhotosHandle)(NSArray<UIImage *> *photos, NSArray *assets);
typedef void(^CLPickingVideoHandle)(UIImage *videoCover, NSURL *videoURL);
typedef void(^CLPickerCancelHandle)(void);
typedef void(^CLPickerShootVideoHandle)(void);

@class CLPhotoModel;
@protocol CLPickerRootControllerDelegate;
@interface CLPickerRootController : UINavigationController

/**
 启动选择器前状态栏样式 默认UIStatusBarStyleLightContent
 previous status bar style defatlt UIStatusBarStyleLightContent
 */
@property (nonatomic, assign) UIStatusBarStyle previousStatusBarStyle;

/**
 默认 白色状态栏
 default UIStatusBarStyleLightContent
 */
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

/**
 是否允许旋转
 default NO
 */
@property (nonatomic, assign) BOOL allowAutorotate;

/**
 选择器背景色 默认白色
 background color default whiteColor
 */
@property (nonatomic) UIColor *backgroundColor;

/**
 导航栏背景色 默认 grayColor
 navigation color default grayColor
 */
@property (nonatomic) UIColor *navigationColor;

/**
 导航栏背景图
 */
@property (nonatomic) UIImage *navigationBarImage;

/**
 标题颜色 默认白色
 title color default whiteColor
 */
@property (nonatomic) UIColor *titleColor;

/**
 导航栏按钮字体颜色 默认白色
 navigation item color default CLBarItemTitleDefaultColor
 */
@property (nonatomic) UIColor *navigationItemColor;

/**
 底部控制栏背景色 默认和导航栏背景色相同
 bottom tool bar backgroundColor default same navigationColor
 */
@property (nonatomic) UIColor *toolBarBackgroundColor;

/**
 底部控制栏按钮颜色 默认和导航栏按钮颜色相同
 bottom tool bar item color default same navigationItemColor
 */
@property (nonatomic) UIColor *toolBarItemColor;

#pragma mark -
/**
 选择图片较小的一边 不超过(750, 750)
 select image min size, Default is (750, 750)
 */
@property (nonatomic, assign) CGSize    minSize;

@property (nonatomic, assign) NSInteger columnCount;                // default ipad:5 else 3
@property (nonatomic, assign) CGFloat   minimumInteritemSpacing;    // default 1.0
@property (nonatomic, assign) CGFloat   minimumLineSpacing;         // default 1.0
@property (nonatomic, assign) UIEdgeInsets sectionInset;            // default UIEdgeInsetsMake(1, 0, 1, 0)

@property (nonatomic, assign) NSInteger maxSelectCount;             // image max default 9
@property (nonatomic, assign) CGFloat minDuration;                  // default 0.0
@property (nonatomic, assign) CGFloat maxDuration;                  // default MAXFLOAT
@property (nonatomic, assign) CGFloat outputVideoScale;             // default 16/9, 注:0为不处理比例
@property (nonatomic, assign) BOOL isDistinguishWH;                 // 是否区分视频宽高比(outputScale宽高比是否可以互换), default NO
@property (nonatomic, assign) BOOL allowEditVideo;                  // default YES

@property (nonatomic, assign) BOOL allowAlbumDropDown;              // default NO (是否下拉选择相册)
@property (nonatomic, assign) BOOL allowPanGestureSelect;           // default YES
@property (nonatomic, assign) BOOL allowPreviewImage;               // default YES
@property (nonatomic, assign) BOOL allowEditImage;                  // default NO
@property (nonatomic, assign) BOOL allowSelectOriginalImage;        // default NO
@property (nonatomic, assign) BOOL allowDoneOnToolBar;              // default YES

@property (nonatomic, assign) BOOL allowSelectGif;                  // default YES
@property (nonatomic, assign) BOOL allowSelectLivePhoto;            // default YES
@property (nonatomic, assign) BOOL allowTakePhoto;                  // default YES
@property (nonatomic, assign) BOOL sortAscending;                   // default NO
@property (nonatomic, assign) BOOL showCaptureOnCell;               // default NO
@property (nonatomic, assign) BOOL usedCustomRecording;             // default NO
@property (nonatomic, assign) CLPickerSelectMode selectMode;        // default CLPickerSelectModeMixDisplay
@property (nonatomic, strong) NSArray *selectedAssets;              
    
#pragma mark -- Delegate | Block --
@property (nonatomic, weak) id<CLPickerRootControllerDelegate>pickerDelegate;
@property (nonatomic, copy) CLPickingPhotosHandle   pickingPhotosHandle;
@property (nonatomic, copy) CLPickingVideoHandle    pickingVideoHandle;
@property (nonatomic, copy) CLPickerCancelHandle    pickerCancelHandle;
@property (nonatomic, copy) CLPickerShootVideoHandle pickerShootVideoHandle;

@property (nonatomic, strong) NSMutableArray<CLPhotoModel *> *selectedModels;
@property (nonatomic, assign) BOOL selectedOriginalImage;

- (void)clickCancelAction;
- (void)clickShootVideoAction;
- (void)didFinishPickingPhotosAction;
- (void)clickPickingVideoActionForAsset:(AVAsset *)asset range:(CMTimeRange)range;
- (void)cancelExport;

- (void)showText:(NSString *)text;
- (void)showText:(NSString *)text delay:(NSTimeInterval)delay;
- (void)showProgress;
- (void)showProgressWithText:(NSString *)text;
- (void)hideProgress;

@end

@protocol CLPickerRootControllerDelegate <UINavigationControllerDelegate>

@optional

// images
- (void)clPickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos assets:(NSArray *)assets;

// video
- (void)clPickerController:(CLPickerRootController *)picker didFinishPickingVideoCover:(UIImage *)videoCover videoURL:(NSURL *)videoURL;

// Cancel Picker
- (void)clPickerControllerDidCancel:(CLPickerRootController *)picker;

// User can write Custom video camera.
- (void)clPickerControllerDidShootVideo:(CLPickerRootController *)picker;

@end

@interface CLAlbumPickerController : UIViewController

@end
