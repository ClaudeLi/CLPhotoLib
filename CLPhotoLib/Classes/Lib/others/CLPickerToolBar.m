//
//  CLPickerToolBar.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/4.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPickerToolBar.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

static CGFloat itemSpacing  = 10.0f;
static CGFloat itemMargin   = 10.0f;

@interface CLPickerToolBar ()

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@property (nonatomic, assign) CGFloat pWidth;
@property (nonatomic, assign) CGFloat eWidth;
@property (nonatomic, assign) CGFloat oWidth;
@property (nonatomic, assign) CGFloat dWidth;

@end

@implementation CLPickerToolBar

- (void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    if (_previewBtn) {
        [_previewBtn setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
        [_previewBtn setTitleColor:_titleColor forState:UIControlStateSelected];
    }
    if (_editBtn) {
        [_editBtn setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
        [_editBtn setTitleColor:_titleColor forState:UIControlStateSelected];
    }
    if (_originalBtn) {
        [_originalBtn setTitleColor:_titleColor forState:UIControlStateNormal];
    }
    if (_tipLabel) {
        [_tipLabel setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
    }
    if (_doneBtn) {
        _doneBtn.titleColor = _titleColor;
    }
    if (_indicatorView) {
        _indicatorView.color = _titleColor;
    }
}

- (void)setEditSelect:(BOOL)editSelect {
    _editSelect = editSelect;
    if (_editBtn) {
        _editBtn.selected = _editSelect;
    }
}

- (void)startAnimating {
    [self.originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
    [self.indicatorView startAnimating];
}

- (void)stopAnimating {
    [self.indicatorView stopAnimating];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        inset = self.safeAreaInsets;
    }
    if (_previewBtn) {
        _previewBtn.frame = CGRectMake(inset.left + itemMargin, 0, self.pWidth, CLToolBarHeight);
    }
    CGFloat previewRight = _previewBtn?(_previewBtn.right+itemSpacing):(inset.left + itemMargin);
    if (_editBtn) {
        _editBtn.frame = CGRectMake(previewRight, 0, self.eWidth, CLToolBarHeight);
    }
    if (_originalBtn) {
        _originalBtn.frame = CGRectMake(_editBtn?(_editBtn.right+itemSpacing):previewRight, 0, self.oWidth + 100, CLToolBarHeight);
        _indicatorView.center = CGPointMake(_originalBtn.left + self.oWidth + 28, CLToolBarHeight/2.0);
    }
    if (_doneBtn) {
        CGFloat doneWidth = self.dWidth + _fontSize + 2;
        if (_tipLabel) {
            _tipLabel.frame = CGRectMake(_editBtn?(_editBtn.right+itemSpacing-5):previewRight, 0, self.width - (_editBtn?(_editBtn.right+itemSpacing):previewRight) - doneWidth - 10, CLToolBarHeight);
        }
        _doneBtn.frame = CGRectMake(self.width - inset.right - itemMargin - doneWidth, 0, doneWidth, CLToolBarHeight);
    }
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)clickPreviewBtn:(UIButton *)sender {
    if (sender.selected) {
        if (self.clickPreviewBlock) {
            self.clickPreviewBlock();
        }
    }
}

- (void)clickEditBtn:(UIButton *)sender {
    if (sender.selected) {
        if (self.clickEditBlock) {
            self.clickEditBlock();
        }
    }
}

- (void)clickOriginalBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.clickOriginalBlock) {
        self.clickOriginalBlock(sender.selected);
    }
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UIButton *)previewBtn {
    if (!_previewBtn) {
        _previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_previewBtn setTitle:CLString(@"CLText_Preview") forState:UIControlStateNormal];
        _previewBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
        if (_titleColor) {
            [_previewBtn setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
            [_previewBtn setTitleColor:_titleColor forState:UIControlStateSelected];
        }
        [_previewBtn addTarget:self action:@selector(clickPreviewBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_previewBtn];
    }
    return _previewBtn;
}

- (UIButton *)editBtn {
    if (!_editBtn) {
        _editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_editBtn setTitle:CLString(@"CLText_Edit") forState:UIControlStateNormal];
        if (_titleColor) {
            [_editBtn setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
            [_editBtn setTitleColor:_titleColor forState:UIControlStateSelected];
        }
        _editBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _editBtn.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
        [_editBtn addTarget:self action:@selector(clickEditBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_editBtn];
    }
    return _editBtn;
}

- (UIButton *)originalBtn {
    if (!_originalBtn) {
        _originalBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_originalBtn setImage:[UIImage imageNamedFromBundle:@"btn_original_unselected"] forState:UIControlStateNormal];
        [_originalBtn setImage:[UIImage imageNamedFromBundle:@"btn_original_unselected"] forState:UIControlStateHighlighted];
        [_originalBtn setImage:[UIImage imageNamedFromBundle:@"btn_original_selected"] forState:UIControlStateSelected];
        [_originalBtn setImage:[UIImage imageNamedFromBundle:@"btn_original_selected"] forState:UIControlStateSelected|UIControlStateHighlighted];
        [_originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
        if (_titleColor) {
            [_originalBtn setTitleColor:_titleColor forState:UIControlStateNormal];
        }
        _originalBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _originalBtn.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
        _originalBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_originalBtn addTarget:self action:@selector(clickOriginalBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_originalBtn];
        [self addSubview:self.indicatorView];
    }
    return _originalBtn;
}

- (UIButton *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [UIButton buttonWithType:UIButtonTypeCustom];
        _tipLabel.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
        _tipLabel.titleLabel.adjustsFontSizeToFitWidth = YES;
        _tipLabel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        if (_titleColor) {
            [_tipLabel setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
        }
        _tipLabel.enabled = NO;
        [self addSubview:_tipLabel];
    }
    return _tipLabel;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _indicatorView.hidesWhenStopped = YES;
        if (_titleColor) {
            _indicatorView.color = _titleColor;
        }
    }
    return _indicatorView;
}

- (CLDoneButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [CLDoneButton buttonWithType:UIButtonTypeCustom];
        if (_titleColor) {
            _doneBtn.titleColor = _titleColor;
        }
        [self addSubview:_doneBtn];
    }
    return _doneBtn;
}

- (CGFloat)pWidth {
    if (!_pWidth) {
        _pWidth = GetMatchValue(CLString(@"CLText_Preview"), _fontSize, YES, CLToolBarHeight)?:0.01;
    }
    return _pWidth;
}

- (CGFloat)eWidth {
    if (!_eWidth) {
        _eWidth = GetMatchValue(CLString(@"CLText_Edit"), _fontSize, YES, CLToolBarHeight)?:0.01;
    }
    return _eWidth;
}

- (CGFloat)oWidth {
    if (!_oWidth) {
        _oWidth = GetMatchValue(CLString(@"CLText_Original"), _fontSize, YES, CLToolBarHeight)?:0.01;
    }
    return _oWidth;
}

- (CGFloat)dWidth {
    if (!_dWidth) {
        _dWidth = GetMatchValue(CLString(@"CLText_Done"), _fontSize, YES, CLToolBarHeight)?:0.01;
    }
    return _dWidth;
}

@end

@interface CLDoneButton ()

@property (nonatomic, strong) UILabel *numberLabel;

@end

@implementation CLDoneButton

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setUp];
    }
    return self;
}

- (void)_setUp {
    [self setTitle:CLString(@"CLText_Done") forState:UIControlStateNormal];
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self addTarget:self action:@selector(clickDoneBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.titleFontSize = CLToolBarTitleFontSize;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.numberLabel.frame = CGRectMake(0, (self.height - (_titleFontSize + 1))/2.0, (_titleFontSize + 1), _titleFontSize + 1);
}

- (void)setTitleFontSize:(CGFloat)titleFontSize {
    _titleFontSize = titleFontSize;
    self.titleLabel.font = [UIFont systemFontOfSize:_titleFontSize];
    self.numberLabel.font = [UIFont systemFontOfSize:(_titleFontSize - 1)];
    self.numberLabel.layer.cornerRadius = (_titleFontSize + 1)/2.0f;
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    [self setTitleColor:[_titleColor colorWithAlphaComponent:CLBarEnabledAlpha] forState:UIControlStateNormal];
    [self setTitleColor:_titleColor forState:UIControlStateSelected];
}

- (void)setNumberColor:(UIColor *)numberColor {
    _numberColor = numberColor;
    self.numberLabel.textColor = _numberColor;
}

- (void)setNumber:(NSInteger)number {
    if (_number != number) {
        _number = number;
        self.selected = _number > 0;
        if (_number) {
            self.numberLabel.hidden = NO;
            self.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)number];
            [UIView showOscillatoryAnimationWithLayer:_numberLabel.layer type:CLOscillatoryAnimationToSmaller];
        } else {
            _numberLabel.hidden = YES;
        }
    }
}

- (void)clickDoneBtn:(CLDoneButton *)sender {
    if (sender.selected) {
        if (self.clickDoneBlock) {
            self.clickDoneBlock();
        }
    }
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UILabel *)numberLabel {
    if (!_numberLabel) {
        _numberLabel = [[UILabel alloc] init];
        _numberLabel.backgroundColor = _titleColor?:CLBarItemTitleDefaultColor;
        _numberLabel.layer.masksToBounds = YES;
        _numberLabel.textAlignment = NSTextAlignmentCenter;
        _numberLabel.adjustsFontSizeToFitWidth = YES;
        _numberLabel.hidden = YES;
        [self addSubview:_numberLabel];
    }
    return _numberLabel;
}

@end
