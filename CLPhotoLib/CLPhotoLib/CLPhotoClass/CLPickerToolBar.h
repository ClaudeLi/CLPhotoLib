//
//  CLPickerToolBar.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/4.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLDoneButton;
@interface CLPickerToolBar : UIView

@property (nonatomic, strong) UIButton *previewBtn;
@property (nonatomic, strong) UIButton *editBtn;
@property (nonatomic, strong) UIButton *originalBtn;
@property (nonatomic, strong) UIButton *tipLabel;
@property (nonatomic, strong) CLDoneButton *doneBtn;

@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, copy) void(^clickPreviewBlock)(void);
@property (nonatomic, copy) void(^clickEditBlock)(void);
@property (nonatomic, copy) void(^clickOriginalBlock)(BOOL selected);

@property (nonatomic, assign) BOOL editSelect;

- (void)startAnimating;
- (void)stopAnimating;

@end


@interface CLDoneButton : UIButton

@property (nonatomic, strong) UIColor  *numberColor;
@property (nonatomic, strong) UIColor  *titleColor;
@property (nonatomic, assign) CGFloat   titleFontSize;

@property (nonatomic, assign) NSInteger number;

@property (nonatomic, copy) void(^clickDoneBlock)(void);

@end
