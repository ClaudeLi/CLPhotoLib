//
//  CLPhotoLib.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/30.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#ifndef CLPhotoLib_h
#define CLPhotoLib_h

#import "CLPickerRootController.h"
#import "CLImageManager.h"

#import "UIView+CLExt.h"
#import "UIImage+CLImage.h"

#define iOS7Later ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
#define iOS9_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

// weakSelf
#define CL_WS(weakSelf)      __weak __typeof(&*self)weakSelf = self;

#define CL_Weak(type)        __weak typeof(type)weak##type = type;
#define CL_StrongWeak(type)  __strong typeof(type)type = weak##type;

// RGBA
#define CL_RGBA(r, g, b, a)    [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define CLScreenWidth    [UIScreen mainScreen].bounds.size.width
#define CLScreenHeight   [UIScreen mainScreen].bounds.size.height
#define CLToolBarHeight     49.0f
#define CLNavigationHeight  64.0f
#define CLStateHeight       20.0f
#define CLTitleHeight       44.0f

// 相册cell高度
#define CLAlbumRowHeight    70.0f


// 已选择数字背景色
#define CLNumBGViewNormalColor    CL_RGBA(83, 179, 17, 1)
#define CLNumBGViewDisabledColor  CL_RGBA(83, 179, 17, 0.5)

// 系统NavigationBar 底色及透明度
#define CLNavigatinBar_Color   CL_RGBA(27, 30, 39, 1)
#define CLNavigatinBar_Alpha   0.98f

// 图片预览/视频预览页navigationBar
#define CLCustomNavColor       CL_RGBA(34, 34, 34, 1)
#define CLCustomNav_Alpha      0.7f

#define CLBgViewColor          CL_RGBA(34, 36, 46, 1)
#define CLToolBarColor         CL_RGBA(253, 253, 253, 1)


// 当前设备 iphone / ipad
#define CLCurrentDevice   [UIDevice currentDevice].model

#define CLPermissionsTips(appName) [NSString stringWithFormat:@"请在%@的\"设置-隐私-照片\"选项中，\r允许%@访问你的手机相册。", CLCurrentDevice, appName]

#endif /* CLPhotoLib_h */
