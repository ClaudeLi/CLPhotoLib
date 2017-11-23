//
//  CLTouchViewController.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/18.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLPhotoModel;
@interface CLTouchViewController : UIViewController

@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong) CLPhotoModel *model;

@end
