//
//  CLAssetCell.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "CLAssetCell.h"
#import "CLAssetModel.h"
#import "CLPhotoLib.h"

@interface CLAssetCell ()
@property (weak, nonatomic) UIImageView *imageView;       // The photo / 照片
@property (weak, nonatomic) UIImageView *selectImageView;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UILabel *timeLength;

@property (nonatomic, weak) UIImageView *viewImgView;

@end

@implementation CLAssetCell

// Now we use code to create subViews for improve performance
// 现在我们用代码来创建CLAssetCell和CLAlbumCell的子控件，以提高性能
//- (void)awakeFromNib {
//    self.timeLength.font = [UIFont boldSystemFontOfSize:11];
//}


- (void)setModel:(CLAssetModel *)model {
    _model = model;
    if (iOS8Later) {
        self.representedAssetIdentifier = [[CLImageManager manager] getAssetIdentifier:model.asset];
    }
    PHImageRequestID imageRequestID = [[CLImageManager manager] getPhotoWithAsset:model.asset photoWidth:self.cl_width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        // Set the cell's thumbnail image if it's still showing the same asset.
        if (!iOS8Later) {
            self.imageView.image = photo; return;
        }
        if ([self.representedAssetIdentifier isEqualToString:[[CLImageManager manager] getAssetIdentifier:model.asset]]) {
            self.imageView.image = photo;
        } else {
            // NSLog(@"this cell is showing other asset");
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        }
        if (!isDegraded) {
            self.imageRequestID = 0;
        }
    }];
    if (imageRequestID && self.imageRequestID && imageRequestID != self.imageRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        // NSLog(@"cancelImageRequest %d",self.imageRequestID);
    }
    self.imageRequestID = imageRequestID;
    self.selectPhotoButton.selected = model.isSelected;
    self.selectImageView.image = self.selectPhotoButton.isSelected ? [UIImage imageNamedFromCLBundle:@"photo_sel_photoPickerVc.png"] : [UIImage imageNamedFromCLBundle:@"photo_def_photoPickerVc.png"];
    self.type = CLAssetCellTypePhoto;
    if (model.type == CLAssetModelMediaTypeLivePhoto)      self.type = CLAssetCellTypeLivePhoto;
    else if (model.type == CLAssetModelMediaTypeAudio)     self.type = CLAssetCellTypeAudio;
    else if (model.type == CLAssetModelMediaTypeVideo) {
        self.type = CLAssetCellTypeVideo;
        self.timeLength.text = model.timeLength;
    }
}

- (void)setType:(CLAssetCellType)type {
    _type = type;
    if (type == CLAssetCellTypePhoto || type == CLAssetCellTypeLivePhoto) {
        _selectImageView.hidden = NO;
        _selectPhotoButton.hidden = NO;
        _bottomView.hidden = YES;
    } else {
        _selectImageView.hidden = NO;
        _selectPhotoButton.hidden = NO;
        _bottomView.hidden = NO;
    }
}

- (void)selectPhotoButtonClick:(UIButton *)sender {
    if (self.didSelectPhotoBlock) {
        self.didSelectPhotoBlock(sender.isSelected);
    }
    self.selectImageView.image = sender.isSelected ? [UIImage imageNamedFromCLBundle:@"photo_sel_photoPickerVc.png"] : [UIImage imageNamedFromCLBundle:@"photo_def_photoPickerVc.png"];
    if (sender.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:_selectImageView.layer type:CLOscillatoryAnimationToBigger];
    }
}

#pragma mark - Lazy load

- (UIButton *)selectPhotoButton {
    if (_selectImageView == nil) {
        UIButton *selectImageView = [[UIButton alloc] init];
        selectImageView.frame = CGRectMake(self.cl_width - 44, 0, 44, 44);
        [selectImageView addTarget:self action:@selector(selectPhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:selectImageView];
        _selectPhotoButton = selectImageView;
    }
    return _selectPhotoButton;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(0, 0, self.cl_width, self.cl_height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.layer.borderWidth = 0.3;
        imageView.layer.borderColor = CLBgViewColor.CGColor;
        [self.contentView addSubview:imageView];
        _imageView = imageView;
        
        [self.contentView bringSubviewToFront:_selectImageView];
        [self.contentView bringSubviewToFront:_bottomView];
    }
    return _imageView;
}

- (UIImageView *)selectImageView {
    if (_selectImageView == nil) {
        UIImageView *selectImageView = [[UIImageView alloc] init];
        selectImageView.frame = CGRectMake(self.cl_width - 27, 0, 27, 27);
        [self.contentView addSubview:selectImageView];
        _selectImageView = selectImageView;
    }
    return _selectImageView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        UIView *bottomView = [[UIView alloc] init];
        bottomView.frame = CGRectMake(0, self.cl_height - 17, self.cl_width, 17);
        bottomView.backgroundColor = [UIColor blackColor];
        bottomView.alpha = 0.8;
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}

- (UIImageView *)viewImgView {
    if (_viewImgView == nil) {
        UIImageView *viewImgView = [[UIImageView alloc] init];
        viewImgView.frame = CGRectMake(8, 0, 17, 17);
        [viewImgView setImage:[UIImage imageNamedFromCLBundle:@"VideoSendIcon.png"]];
        [self.bottomView addSubview:viewImgView];
        _viewImgView = viewImgView;
    }
    return _viewImgView;
}

- (UILabel *)timeLength {
    if (_timeLength == nil) {
        UILabel *timeLength = [[UILabel alloc] init];
        timeLength.font = [UIFont boldSystemFontOfSize:11];
        timeLength.frame = CGRectMake(self.viewImgView.cl_right, 0, self.cl_width - self.viewImgView.cl_right - 5, 17);
        timeLength.textColor = [UIColor whiteColor];
        timeLength.textAlignment = NSTextAlignmentRight;
        [self.bottomView addSubview:timeLength];
        _timeLength = timeLength;
    }
    return _timeLength;
}

@end



@interface CLAlbumCell ()
@property (weak, nonatomic) UIImageView *posterImageView;
@property (weak, nonatomic) UILabel *titleLable;
@property (weak, nonatomic) UIImageView *arrowImageView;
@end

@implementation CLAlbumCell

/*
 - (void)awakeFromNib {
 self.posterImageView.clipsToBounds = YES;
 }
 */

- (void)setModel:(CLAlbumModel *)model {
    _model = model;
    
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:model.name attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor blackColor]}];
    NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)",model.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    [nameString appendAttributedString:countString];
    self.titleLable.attributedText = nameString;
    [[CLImageManager manager] getPostImageWithAlbumModel:model completion:^(UIImage *postImage) {
        self.posterImageView.image = postImage;
    }];
    if (model.selectedCount) {
        self.selectedCountButton.hidden = NO;
        [self.selectedCountButton setTitle:[NSString stringWithFormat:@"%zd",model.selectedCount] forState:UIControlStateNormal];
    } else {
        self.selectedCountButton.hidden = YES;
    }
}

/// For fitting iOS6
- (void)layoutSubviews {
    if (iOS7Later) [super layoutSubviews];
    _selectedCountButton.frame = CGRectMake(self.cl_width - 24 - 30, 23, 24, 24);
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if (iOS7Later) [super layoutSublayersOfLayer:layer];
}

#pragma mark - Lazy load

- (UIImageView *)posterImageView {
    if (_arrowImageView == nil) {
        UIImageView *posterImageView = [[UIImageView alloc] init];
        posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        posterImageView.clipsToBounds = YES;
        posterImageView.frame = CGRectMake(0, 0, 70, 70);
        [self.contentView addSubview:posterImageView];
        _posterImageView = posterImageView;
    }
    return _posterImageView;
}

- (UILabel *)titleLable {
    if (_titleLable == nil) {
        UILabel *titleLable = [[UILabel alloc] init];
        titleLable.font = [UIFont boldSystemFontOfSize:17];
        titleLable.frame = CGRectMake(80, 0, self.cl_width - 80 - 50, self.cl_height);
        titleLable.textColor = [UIColor blackColor];
        titleLable.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:titleLable];
        _titleLable = titleLable;
    }
    return _titleLable;
}

- (UIImageView *)arrowImageView {
    if (_arrowImageView == nil) {
        UIImageView *arrowImageView = [[UIImageView alloc] init];
        CGFloat arrowWH = 15;
        arrowImageView.frame = CGRectMake(self.cl_width - arrowWH - 12, 28, arrowWH, arrowWH);
        [arrowImageView setImage:[UIImage imageNamedFromCLBundle:@"TableViewArrow.png"]];
        [self.contentView addSubview:arrowImageView];
        _arrowImageView = arrowImageView;
    }
    return _arrowImageView;
}

- (UIButton *)selectedCountButton {
    if (_selectedCountButton == nil) {
        UIButton *selectedCountButton = [[UIButton alloc] init];
        selectedCountButton.layer.cornerRadius = 12;
        selectedCountButton.clipsToBounds = YES;
        selectedCountButton.backgroundColor = [UIColor redColor];
        [selectedCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        selectedCountButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:selectedCountButton];
        _selectedCountButton = selectedCountButton;
    }
    return _selectedCountButton;
}

@end



@implementation CLAssetCameraCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end

