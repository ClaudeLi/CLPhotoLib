//
//  CLConfig.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#ifndef CLConfig_h
#define CLConfig_h

#ifdef DEBUG
#define CLLog(format, ...) printf("\n[%s] %s [in line %d] => %s\n", __TIME__, __FUNCTION__, __LINE__, [[NSString stringWithFormat:format, ## __VA_ARGS__] UTF8String]);
#else
#define CLLog(format, ...)
#endif

// weak/Strong
#define cl_WS(weakSelf)                 __weak __typeof(&*self) weakSelf = self
#define cl_weakSelf(var)                __weak typeof(var) weakSelf = var
#define cl_strongSelf(var)              __strong typeof(var) strongSelf = var
#define cl_weakify(obj, weakObj)        __weak typeof(obj) weakObj = obj
#define cl_strongify(obj, strongObj)    __strong typeof(obj) strongObj = obj

#define CLColor_RGBA(r, g, b, a)        [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];
// Bar Item Title Color
#define CLBarItemTitleDefaultColor      CLColor_RGBA(255, 219, 15, 1)
// Album Seleted Round Color
#define CLAlbumSeletedRoundColor        CLColor_RGBA(255, 219, 15, 1)

// 视频填充色
 #define CLVideoFillColor               [UIColor blackColor]
// 视频输出比例
static CGFloat CLVideoOutputScale       = 16.0/9.0;

static CGFloat CLBarAlpha               = 0.97;
static CGFloat CLToolBarAlpha           = 0.9;
static CGFloat CLBarEnabledAlpha        = 0.4;
static CGFloat CLShadowViewAlpha        = 0.2;

static CGFloat CLNavigationItemFontSize = 16.0;
static CGFloat CLToolBarTitleFontSize   = 16.0;
static CGFloat CLToolBarHeight          = 42.0;

static CGFloat CLAlbumDropDownScale     = 0.7;

static CGFloat CLAlbumDropDownAnimationTime = 0.3;
static CGFloat CLAlbumPackUpAnimationTime   = 0.2;
static CGFloat CLLittleControlAnimationTime = 0.2;

static inline CGFloat CLAlbumRowHeight(void) {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 90.0f;
    } else {
        return 70.0f;
    }
}

// 视频输出路径
static inline NSString *CLVideoOutputPath(void) {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *str = [NSString stringWithFormat:@"%.0f.mp4", time];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:str];
}

static inline CGFloat GetMatchValue(NSString *text, CGFloat fontSize, BOOL isHeightFixed, CGFloat fixedValue) {
    CGSize size;
    if (isHeightFixed) {
        size = CGSizeMake(MAXFLOAT, fixedValue);
    } else {
        size = CGSizeMake(fixedValue, MAXFLOAT);
    }
    CGSize resultSize;
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        //返回计算出的size
        resultSize = [text boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]} context:nil].size;
    }
    if (isHeightFixed) {
        return resultSize.width;
    } else {
        return resultSize.height;
    }
}

#endif /* CLConfig_h */
