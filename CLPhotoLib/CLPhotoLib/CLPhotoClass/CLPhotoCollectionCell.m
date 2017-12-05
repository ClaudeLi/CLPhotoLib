//
//  CLPhotoCollectionCell.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPhotoCollectionCell.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

#pragma mark -
#pragma mark -- CLPhotoCollectionCell --
static CGFloat selectBtnWidth       = 35.0f;
static CGFloat bottomViewHeight     = 16.0f;
static CGFloat CLTimeLabelFontSize  = 12.0f;

@interface CLPhotoCollectionCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView      *shadowView;
@property (nonatomic, strong) UIImageView *bottomView;

@property (nonatomic, strong) UIImageView *liveImageView;
@property (nonatomic, strong) UIImageView *videoImageView;
@property (nonatomic, strong) UILabel     *typeLabel;

@property (nonatomic, copy)   NSString    *localIdentifier;
@property (nonatomic, assign) PHImageRequestID imageRequestID;

@end


@implementation CLPhotoCollectionCell

- (void)setModel:(CLPhotoModel *)model{
    _model = model;
    _selectButton.hidden = NO;
    _selectButton.enabled = YES;
    if (_model.type == CLAssetMediaTypeVideo) {
        _selectButton.hidden = YES;
        _selectButton.enabled = NO;
        _liveImageView.hidden = YES;
        self.bottomView.hidden = NO;
        self.videoImageView.hidden = NO;
        self.typeLabel.text = model.timeFormat;
    } else if (_model.type == CLAssetMediaTypeGif) {
        _videoImageView.hidden = YES;
        _liveImageView.hidden = YES;
        self.bottomView.hidden = !CLAllowSelectGif;
        self.typeLabel.text = @"GIF";
    } else if (_model.type == CLAssetMediaTypeLivePhoto) {
        _videoImageView.hidden = YES;
        self.bottomView.hidden = !CLAllowSelectLivePhoto;
        self.liveImageView.hidden = NO;
        self.typeLabel.text = @"Live";
    } else {
        self.bottomView.hidden = YES;
    }
    _selectButton.selected = model.isSelected;
    _shadowView.alpha = model.isSelected;
    if (model.asset && self.imageRequestID >= PHInvalidImageRequestID) {
        [[PHCachingImageManager defaultManager] cancelImageRequest:self.imageRequestID];
    }
    self.localIdentifier = model.asset.localIdentifier;
    self.imageView.image = nil;
    cl_weakSelf(self);
    self.imageRequestID = [CLPhotoShareManager requestCustomImageForAsset:model.asset size:CGSizeMake(self.width * [UIScreen mainScreen].scale, self.width * [UIScreen mainScreen].scale) completion:^(UIImage *image, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if ([strongSelf.localIdentifier isEqualToString:model.asset.localIdentifier]) {
            strongSelf.imageView.image = image;
        }
        if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
            strongSelf.imageRequestID = -1;
        }
    }];
}

#pragma mark -- Initial Methods --
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView.hidden = NO;
        self.shadowView.alpha = 0;
        self.selectButton.hidden = YES;
        self.bottomView.hidden = YES;
        self.liveImageView.hidden = NO;
        self.videoImageView.hidden = NO;
        self.typeLabel.hidden = NO;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    _imageView.frame    = self.bounds;
    _shadowView.frame   = _imageView.bounds;
    _selectButton.frame = CGRectMake(self.width - selectBtnWidth, 0, selectBtnWidth, selectBtnWidth);
    _bottomView.frame   = CGRectMake(0, self.height-bottomViewHeight, self.width, bottomViewHeight);
    _liveImageView.frame  = CGRectMake(5, (bottomViewHeight - 16)/2.0 - 2, 16, 16);
    _videoImageView.frame = CGRectMake(5, (bottomViewHeight - 11)/2.0, 16, 11);
    _typeLabel.frame = CGRectMake(30, 0, self.width - 35, bottomViewHeight);
}

#pragma mark -- Lazy Loads --
- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UIView *)shadowView{
    if (!_shadowView) {
        _shadowView = [UIView new];
        _shadowView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:CLShadowViewAlpha];
        [self.imageView addSubview:_shadowView];
    }
    return _shadowView;
}

- (UIButton *)selectButton{
    if (!_selectButton) {
        _selectButton = [[UIButton alloc] init];
        [_selectButton setImage:[UIImage imageNamedFromBundle:@"btn_photo_unselected"] forState:UIControlStateNormal];
        [_selectButton setImage:[UIImage imageNamedFromBundle:@"btn_photo_unselected"] forState:UIControlStateHighlighted];
        [_selectButton setImage:[UIImage imageNamedFromBundle:@"btn_photo_selected"] forState:UIControlStateSelected];
        [_selectButton setImage:[UIImage imageNamedFromBundle:@"btn_photo_selected"] forState:UIControlStateSelected|UIControlStateHighlighted];
        [_selectButton addTarget:self action:@selector(clickSelectButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_selectButton];
        [_selectButton setEnlargeEdgeWithTop:0 right:0 bottom:10 left:10];
    }
    return _selectButton;
}

- (UIImageView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromBundle:@"clicon_photo_shadow"]];
        [self.contentView addSubview:_bottomView];
    }
    return _bottomView;
}

- (UIImageView *)liveImageView{
    if (!_liveImageView) {
        _liveImageView = [[UIImageView alloc] init];
        _liveImageView.image = [UIImage imageNamedFromBundle:@"clicon_photo_live"];
        _liveImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.bottomView addSubview:_liveImageView];
    }
    return _liveImageView;
}


- (UIImageView *)videoImageView{
    if (!_videoImageView) {
        _videoImageView = [[UIImageView alloc] init];
        _videoImageView.image = [UIImage imageNamedFromBundle:@"clicon_photo_video"];
        [self.bottomView addSubview:_videoImageView];
    }
    return _videoImageView;
}

- (UILabel *)typeLabel{
    if (!_typeLabel) {
        _typeLabel = [[UILabel alloc] init];
        _typeLabel.textAlignment = NSTextAlignmentRight;
        _typeLabel.font = [UIFont systemFontOfSize:CLTimeLabelFontSize];
        _typeLabel.textColor = [UIColor whiteColor];
        _typeLabel.adjustsFontSizeToFitWidth = YES;
        [self.bottomView addSubview:_typeLabel];
    }
    return _typeLabel;
}

#pragma mark -- Target Methods --
- (void)clickSelectButton:(UIButton *)sender{
    if (self.didSelectPhotoBlock) {
        self.didSelectPhotoBlock(sender.selected);
    }
}

- (void)setSelectBtnSelect:(BOOL)selectBtnSelect{
    _selectBtnSelect = selectBtnSelect;
    self.selectButton.selected = _selectBtnSelect;
    if (self.selectButton.isSelected) {
        [UIView animateWithDuration:CLLittleControlAnimationTime animations:^{
            _shadowView.alpha = 1;
        }];
        [UIView showOscillatoryAnimationWithLayer:self.selectButton.layer type:CLOscillatoryAnimationToBigger];
    }else{
        _shadowView.alpha = 0;
    }
}

@end


#pragma mark -
#pragma mark -- CLTakePhotoCell --
@import AVFoundation;
@interface CLTakePhotoCell ()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) AVCaptureSession      *session;
@property (nonatomic, strong) AVCaptureDeviceInput  *videoInput;
@property (nonatomic, strong) AVCaptureStillImageOutput  *stillImageOutPut;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end
@implementation CLTakePhotoCell

- (void)setShowCaptureOnCell:(BOOL)showCaptureOnCell{
    _showCaptureOnCell = showCaptureOnCell;
    if (_showCaptureOnCell) {
        [self startCapture];
        self.imageView.image = [UIImage imageNamedFromBundle:@"clicon_take_camera"];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }else{
        [self removeSession];
        if (_allowSelectVideo) {
            self.imageView.image = [UIImage imageNamedFromBundle:@"clicon_take_video"];
        }else{
            self.imageView.image = [UIImage imageNamedFromBundle:@"clicon_take_photo"];
        }
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    if (_showCaptureOnCell) {
        _imageView.frame = CGRectMake(0, 0, self.width/3.0, self.width/3.0);
        _imageView.center = self.center;
    }else{
        _imageView.frame = self.bounds;
    }
    _previewLayer.frame = self.contentView.layer.bounds;
}

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = YES;
        [self addSubview:_imageView];
    }
    return _imageView;
}

- (void)restartCapture{
    if (_session) {
        [_session stopRunning];
    }
    [self startCapture];
}

- (void)startCapture{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (![UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] ||
        status == AVAuthorizationStatusRestricted ||
        status == AVAuthorizationStatusDenied) {
        return;
    }
    
    if (self.session && [self.session isRunning]) {
        return;
    }
    [self.session stopRunning];
    [self.session removeInput:self.videoInput];
    [self.session removeOutput:self.stillImageOutPut];
    self.session = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
    
    self.session = [[AVCaptureSession alloc] init];
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:[self backCamera] error:nil];
    self.stillImageOutPut = [[AVCaptureStillImageOutput alloc] init];
    //这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
    NSDictionary *dicOutputSetting = [NSDictionary dictionaryWithObject:AVVideoCodecJPEG forKey:AVVideoCodecKey];
    [self.stillImageOutPut setOutputSettings:dicOutputSetting];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.stillImageOutPut]) {
        [self.session addOutput:self.stillImageOutPut];
    }
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.contentView.layer setMasksToBounds:YES];
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.contentView.layer insertSublayer:self.previewLayer atIndex:0];
    
    [self.session startRunning];
}

- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)removeSession{
    if (_session) {
        [_session stopRunning];
        _session = nil;
    }
}

- (void)dealloc{
    CLLog(@"%s", __func__);
    [self removeSession];
}

@end

#pragma mark -
#pragma mark -- CLAlbumTableViewCell --

static CGFloat rightSelectButtonWidth   = 18.0f;
static CGFloat CLAlbumTitleFontSize     = 15.0f;
static CGFloat CLAlbumSelectFontSize    = 14.0f;

@interface CLAlbumTableViewCell ()

@property (nonatomic, strong) UIImageView   *headImageView;
@property (nonatomic, strong) UILabel       *titleLabel;
@property (nonatomic, strong) UIButton      *selectButton;
@property (nonatomic, strong) UIImageView   *arrowImageView;

@property (nonatomic, copy)   NSString      *localIdentifier;
@end
@implementation CLAlbumTableViewCell

- (void)setModel:(CLAlbumModel *)model{
    _model = model;
    self.headImageView.hidden = NO;
    cl_weakSelf(self);
    self.localIdentifier = model.firstAsset.localIdentifier;
    [CLPhotoShareManager requestCustomImageForAsset:model.firstAsset size:CGSizeMake(CLAlbumRowHeight() * [UIScreen mainScreen].scale, CLAlbumRowHeight() * [UIScreen mainScreen].scale) completion:^(UIImage *image, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if ([strongSelf.localIdentifier isEqualToString:model.firstAsset.localIdentifier]) {
            strongSelf.headImageView.image = image?:[UIImage imageNamedFromBundle:@"icon_default_photo"];
        }
    }];
    if (_model.title) {
        NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:_model.title attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:CLAlbumTitleFontSize],NSForegroundColorAttributeName:[UIColor blackColor]}];
        NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)", _model.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:CLAlbumTitleFontSize],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
        [nameString appendAttributedString:countString];
        self.titleLabel.attributedText = nameString;
    }
    if (_model.selectedCount) {
        self.selectButton.hidden = NO;
        [self.selectButton setTitle:[NSString stringWithFormat:@"%zd", _model.selectedCount] forState:UIControlStateNormal];
    }else{
        _selectButton.hidden = YES;
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryView = self.arrowImageView;
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat hleft = self.width - CGRectGetMinX(self.accessoryView.frame) - 15;
        _headImageView.frame = CGRectMake(hleft>5?hleft:10, 0.5, self.height, self.height - 1.5);
    }else{
        _headImageView.frame = CGRectMake(10, 0.5, self.height, self.height - 1.5);
    }
    _titleLabel.frame = CGRectMake(_headImageView.right + 10, 0, self.width - _headImageView.width - rightSelectButtonWidth - 60, self.height);
    _selectButton.frame = CGRectMake(CGRectGetMinX(self.accessoryView.frame) - rightSelectButtonWidth - 2, (self.height - rightSelectButtonWidth)/2.0, rightSelectButtonWidth, rightSelectButtonWidth);
}

#pragma mark -- Lazy Loads --
- (UIImageView *)headImageView {
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc] init];
        _headImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headImageView.clipsToBounds = YES;
        [self.contentView addSubview:_headImageView];
    }
    return _headImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:CLAlbumTitleFontSize];
        _titleLabel.textColor = [UIColor blackColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_titleLabel];
    }
    return _titleLabel;
}

- (UIButton *)selectButton {
    if (!_selectButton) {
        _selectButton = [[UIButton alloc] init];
        _selectButton.layer.cornerRadius = rightSelectButtonWidth/2.0;
        _selectButton.clipsToBounds = YES;
        _selectButton.backgroundColor = CLAlbumSeletedRoundColor;
        _selectButton.titleLabel.font = [UIFont systemFontOfSize:CLAlbumSelectFontSize];
        _selectButton.userInteractionEnabled = NO;
        _selectButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:_selectButton];
    }
    return _selectButton;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        [_arrowImageView setImage:[UIImage imageNamedFromBundle:@"clicon_photo_arrow"]];
    }
    return _arrowImageView;
}

@end
