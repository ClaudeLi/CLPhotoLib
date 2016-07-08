//
//  CLAlbumTableView.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/7/2.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLAlbumModel;
@interface CLAlbumTableView : UIView

@property (nonatomic, copy) void(^selectAlbumBlock)(CLAlbumModel *model);

@property (nonatomic, copy) void(^disMissBlock)();

@property (nonatomic, strong) NSMutableArray *albumArray;

- (void)showInView:(UIView *)view;
- (void)dismiss;


@end
