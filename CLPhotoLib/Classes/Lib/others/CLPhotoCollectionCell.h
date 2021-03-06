//
//  CLPhotoCollectionCell.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLPhotoModel;
@interface CLPhotoCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UIButton     *selectButton;

@property (nonatomic, strong) CLPhotoModel *model;

@property (nonatomic, copy) void(^didSelectPhotoBlock)(BOOL isSelected);

@property (nonatomic, assign) BOOL selectBtnSelect;

@property (nonatomic, assign) BOOL allowImgMultiple;

@end

@interface CLTakePhotoCell : UICollectionViewCell

@property (nonatomic) BOOL allowSelectVideo;
@property (nonatomic) BOOL showCaptureOnCell;

@end

@class CLAlbumModel;
@interface CLAlbumTableViewCell : UITableViewCell

@property (nonatomic, strong) CLAlbumModel *model;

@end
