//
//  CLPhotoViewController.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXTERN NSNotificationName const CLPhotoLibReloadAlbumList;

@class CLAlbumModel;
@interface CLPhotosViewController : UIViewController

@property (nonatomic, strong) CLAlbumModel *albumModel;

@end
