//
//  CLProgressHUD.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/22.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLProgressHUD.h"

#define CLHUDTitleDefaultFont   [UIFont boldSystemFontOfSize:16]

CGFloat whiteSpace = 10.0f;
@interface CLProgressHUD (){
    NSTimer *_timer;
}

@property (nonatomic, strong) UIView  *hudView;
@property (nonatomic, strong) UILabel *hudLabel;
@property (nonatomic, strong) UIActivityIndicatorView *hudIndicatorView;
@property (nonatomic, assign) CGFloat mainWidth;

@end

@implementation CLProgressHUD

- (instancetype)init{
    self = [super init];
    if (self) {
        self.alpha = 0;
    }
    return self;
}

- (UIView *)hudView{
    if (!_hudView) {
        _hudView = [UIView new];
        _hudView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        _hudView.layer.masksToBounds = YES;
        _hudView.layer.cornerRadius = 6.0f;
        _hudView.alpha = 0;
        [self addSubview:_hudView];
    }
    return _hudView;
}

- (UIActivityIndicatorView *)hudIndicatorView{
    if (!_hudIndicatorView) {
        _hudIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _hudIndicatorView.frame = CGRectMake(0, 0, 30, 30);
        [self.hudView addSubview:_hudIndicatorView];
    }
    return _hudIndicatorView;
}

- (UILabel *)hudLabel{
    if (!_hudLabel) {
        _hudLabel = [UILabel new];
        _hudLabel.textAlignment = NSTextAlignmentCenter;
        _hudLabel.font = CLHUDTitleDefaultFont;
        _hudLabel.textColor = [UIColor whiteColor];
        _hudLabel.adjustsFontSizeToFitWidth = YES;
        [self.hudView addSubview:_hudLabel];
    }
    return _hudLabel;
}

- (CGFloat)mainWidth{
    if (!_mainWidth) {
        _mainWidth = (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) - 40);
    }
    return _mainWidth;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.center = self.superview.center;
    self.hudView.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0);
}

- (void)showText:(NSString *)text{
    [self showText:text delay:1.5f];
}

- (void)showText:(NSString *)text canTouch:(BOOL)canTouch{
    [self showText:text delay:1.5f canTouch:canTouch];
}

- (void)showText:(NSString *)text delay:(NSTimeInterval)delay{
    [self showText:text delay:delay canTouch:YES];
}

- (void)showText:(NSString *)text delay:(NSTimeInterval)delay canTouch:(BOOL)canTouch{
    if (!text.length) {
        return;
    }
    _hudIndicatorView.hidden = YES;
    delay = delay?:1.0;
    CGSize  size = [text sizeWithAttributes:@{NSFontAttributeName:CLHUDTitleDefaultFont}];
    CGFloat width = MIN(size.width, self.mainWidth);
    if (canTouch) {
        self.bounds = CGRectMake(0, 0, width + whiteSpace*2, 60);
        self.hudView.bounds = self.bounds;
    }else{
        self.bounds = self.superview.bounds;
        self.hudView.bounds = CGRectMake(0, 0, width + whiteSpace*2, 60);
    }
    self.center = self.superview.center;
    self.hudLabel.frame = CGRectMake(whiteSpace, 0, width, self.hudView.frame.size.height);
    self.hudLabel.text = text;
    self.hudLabel.hidden = NO;
    [self show];
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(hideProgress) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)showProgress:(BOOL)canTouch{
    _hudLabel.hidden = YES;
    if (canTouch) {
        self.bounds = CGRectMake(0, 0, 68, 68);
        self.hudView.bounds = self.bounds;
    }else{
        self.bounds = self.superview.bounds;
        self.hudView.bounds = CGRectMake(0, 0, 68, 68);
    }
    self.center = self.superview.center;
    self.hudIndicatorView.center = CGPointMake(self.hudView.bounds.size.width/2.0, self.hudView.bounds.size.height/2.0);
    [self.hudIndicatorView startAnimating];
    [self show];
}

- (void)showProgressWithText:(NSString *)text{
    [self showProgressWithText:text canTouch:NO];
}

- (void)showProgressWithText:(NSString *)text canTouch:(BOOL)canTouch{
    if (!text.length) {
        return;
    }
    CGSize  size = [text sizeWithAttributes:@{NSFontAttributeName:CLHUDTitleDefaultFont}];
    CGFloat width = MIN(size.width, self.mainWidth);
    if (canTouch) {
        self.bounds = CGRectMake(0, 0, width + whiteSpace*2, 88);
        self.hudView.bounds = self.bounds;
    }else{
        self.bounds = self.superview.bounds;
        self.hudView.bounds = CGRectMake(0, 0, width + whiteSpace*2, 88);
    }
    self.center = self.superview.center;
    self.hudIndicatorView.center = CGPointMake(self.hudView.bounds.size.width/2.0, 30);
    [self.hudIndicatorView startAnimating];
    self.hudLabel.frame = CGRectMake(whiteSpace, 60, width, size.height);
    self.hudLabel.text = text;
    self.hudLabel.hidden = NO;
    [self show];
}

- (void)hideProgress{
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        _hudView.alpha = 0;
    } completion:^(BOOL finished) {
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        self.hidden = YES;
        _hudView.hidden = YES;
        [_hudIndicatorView stopAnimating];
    }];
}

- (void)show{
    self.hidden = NO;
    self.hudView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
        _hudView.alpha = 1;
    }];
}

@end
