//
//  CLAlbumTableView.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLAlbumModel;
@interface CLAlbumTableView : UIView

@property (nonatomic, strong) UIColor *tableColor;

@property (nonatomic, copy) void(^didSelectAlbumBlock)(CLAlbumModel *model);

@property (nonatomic, copy) void(^disMissAlbumBlock)(void);

@property (nonatomic, copy) NSArray *albumArray;

- (void)reloadData;
- (void)showAlbumAnimated:(BOOL)animated;
- (void)dismiss;

@end
