//
//  CLAssetCell.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    CLAssetCellTypePhoto = 0,
    CLAssetCellTypeLivePhoto,
    CLAssetCellTypeVideo,
    CLAssetCellTypeAudio,
} CLAssetCellType;

@class CLAssetModel;
@interface CLAssetCell : UICollectionViewCell

@property (weak, nonatomic)     UIButton *selectPhotoButton;
@property (nonatomic, strong)   CLAssetModel *model;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL);
@property (nonatomic, assign)   CLAssetCellType type;
@property (nonatomic, copy)     NSString *representedAssetIdentifier;
@property (nonatomic, assign)   PHImageRequestID imageRequestID;

@end


@class CLAlbumModel;
@interface CLAlbumCell : UITableViewCell

@property (nonatomic, strong) CLAlbumModel *model;
@property (weak, nonatomic) UIButton *selectedCountButton;

@end


@interface CLAssetCameraCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end
