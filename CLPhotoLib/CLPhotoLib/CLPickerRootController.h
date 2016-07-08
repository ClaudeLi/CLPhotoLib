//
//  CLPickerRootController.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/30.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CLAssetModel.h"

@protocol CLPickerRootControllerDelegate;
@interface CLPickerRootController : UINavigationController
/// Use this init method / 用这个初始化方法
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<CLPickerRootControllerDelegate>)delegate;
/// This init method just for previewing photos / 用这个初始化方法以预览图片
- (instancetype)initWithSelectedAssets:(NSMutableArray *)selectedAssets selectedPhotos:(NSMutableArray *)selectedPhotos index:(NSInteger)index;

/// Default is 9 / 默认最大可选9张图片
@property (nonatomic, assign) NSInteger maxImagesCount;

/// Sort photos ascending by modificationDate，Default is YES
/// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
@property (nonatomic, assign) BOOL sortAscendingByModificationDate;

/// Default is (750, 750) / 默认图片较小的一边 不超过 minSideSize
@property (nonatomic, assign) CGSize minSideSize;

// Default is 3 /  默认有3竖列  范围 [1-5]
@property (nonatomic, assign) NSInteger listCount;

/// Default is 600px / 默认600像素宽
@property (nonatomic, assign) CGFloat photoPreviewMaxWidth;

/// Default is 15, While fetching photo, HUD will dismiss automatic if timeout;
/// 超时时间，默认为15秒，当取图片时间超过15秒还没有取成功时，会自动dismiss HUD；
@property (nonatomic, assign) NSInteger timeout;

/// Default is YES.if set NO, the original photo button will hide. user can't picking original photo.
/// 默认为YES，如果设置为NO,原图按钮将隐藏，用户不能选择发送原图
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;

/// Default is YES.if set NO, user can't picking video.
/// 默认为YES，如果设置为NO,用户将不能选择发送视频
@property (nonatomic, assign) BOOL allowPickingVideo;

/// Default is YES.if set NO, user can't picking image.
/// 默认为YES，如果设置为NO,用户将不能选择发送图片
@property(nonatomic, assign) BOOL allowPickingImage;

/// Default is YES.if set NO, user can't take picture.
/// 默认为YES，如果设置为NO,拍照按钮将隐藏,用户将不能在选择器中拍照
@property(nonatomic, assign) BOOL allowTakePicture;

// 默认为NO，如果设置为YES, 工具tabBar将隐藏
@property(nonatomic, assign) BOOL allowShowToolBar;

// 默认NO，不能pop返回相册选择页，相册在当前页选择<类似新浪微博>
@property(nonatomic, assign) BOOL canGoBackAlbum;

/// The photos user have selected
/// 用户选中过的图片数组
@property (nonatomic, strong) NSMutableArray *selectedAssets;
@property (nonatomic, strong) NSMutableArray<CLAssetModel *> *selectedModels;

- (void)showAlertWithTitle:(NSString *)title;
- (void)showProgressHUD;
- (void)hideProgressHUD;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;

// The picker should dismiss itself; when it dismissed these handle will be called.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[CLImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的handle
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[CLImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
@property (nonatomic, copy) void (^didFinishPickingPhotosHandle)(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto);
@property (nonatomic, copy) void (^didFinishPickingPhotosWithInfosHandle)(NSArray<UIImage *> *photos,NSArray *assets,BOOL isSelectOriginalPhoto,NSArray<NSDictionary *> *infos);
@property (nonatomic, copy) void (^imagePickerControllerDidCancelHandle)();
// If user picking a video, this handle will be called.
// If system version > iOS8,asset is kind of PHAsset class, else is ALAsset class.
// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
@property (nonatomic, copy) void (^didFinishPickingVideoHandle)(UIImage *coverImage,id asset);

@property (nonatomic, weak) id<CLPickerRootControllerDelegate> pickerDelegate;

@end

@protocol CLPickerRootControllerDelegate <NSObject>
@optional
// The picker should dismiss itself; when it dismissed these handle will be called.
// If isOriginalPhoto is YES, user picked the original photo.
// You can get original photo with asset, by the method [[CLImageManager manager] getOriginalPhotoWithAsset:completion:].
// The UIImage Object in photos default width is 828px, you can set it by photoWidth property.
// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的handle
// 如果isSelectOriginalPhoto为YES，表明用户选择了原图
// 你可以通过一个asset获得原图，通过这个方法：[[CLImageManager manager] getOriginalPhotoWithAsset:completion:]
// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
- (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto;
- (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos;
- (void)imagePickerControllerDidCancel:(CLPickerRootController *)picker;
// If user picking a video, this callback will be called.
// If system version > iOS8,asset is kind of PHAsset class, else is ALAsset class.
// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset;

@end

@interface CLAlbumPickerController : UIViewController

@end
