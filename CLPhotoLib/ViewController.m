//
//  ViewController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 16/7/8.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "ViewController.h"
#import "CLPhotoLib.h"


@interface ViewController ()<CLPickerRootControllerDelegate>{
    NSMutableArray *_assets;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _assets = [NSMutableArray array];
    
    UIButton* photo = [UIButton new];
    photo.frame = CGRectMake(50, 100, 200, 50);
    photo.backgroundColor = [UIColor redColor];
    [photo setTitle:@"choosePhoto" forState:UIControlStateNormal];
    [photo addTarget:self action:@selector(clickButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photo];
}

- (void)clickButtonAction{
    CLPickerRootController *imagePickerVc = [[CLPickerRootController alloc] initWithMaxImagesCount:9 delegate:self];
    // optional, 可选的
    imagePickerVc.selectedAssets = _assets;
    // 在内部显示拍照按钮
    imagePickerVc.allowTakePicture = YES;
    // 设置是否可以选择视频/图片/原图
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    // 照片排列按修改时间升序
    imagePickerVc.sortAscendingByModificationDate = NO;
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

- (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    NSLog(@"%@", photos);
    _assets = [assets mutableCopy];
}

// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
- (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    NSLog(@"%@", asset);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
