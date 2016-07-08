//
//  CLImagePickerController.h
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLAlbumModel;
@interface CLImagePickerController : UIViewController

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) CLAlbumModel *model;

@property (nonatomic, copy) void (^backButtonClickHandle)(CLAlbumModel *model);

@end
