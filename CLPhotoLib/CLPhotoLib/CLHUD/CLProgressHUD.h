//
//  CLProgressHUD.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/22.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLProgressHUD : UIView

// default delay:1.5f, canTouch:YES
- (void)showText:(NSString *)text;
- (void)showText:(NSString *)text canTouch:(BOOL)canTouch;
- (void)showText:(NSString *)text delay:(NSTimeInterval)delay;
- (void)showText:(NSString *)text delay:(NSTimeInterval)delay canTouch:(BOOL)canTouch;

- (void)showProgress:(BOOL)canTouch;
// canTouch:NO
- (void)showProgressWithText:(NSString *)text;
- (void)showProgressWithText:(NSString *)text canTouch:(BOOL)canTouch;

- (void)hideProgress;

@end
