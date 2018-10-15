//
//  CLPreviewViewController.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/7.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLPhotoModel;
@interface CLPreviewViewController : UIViewController

@property (nonatomic, assign) NSInteger     currentIndex;
@property (nonatomic, strong) CLPhotoModel *currentModel;
@property (nonatomic, strong) NSArray <CLPhotoModel *> *photoArray;

@property (nonatomic, copy) void(^didReloadToolBarStatus)(BOOL reloadList);

@end
