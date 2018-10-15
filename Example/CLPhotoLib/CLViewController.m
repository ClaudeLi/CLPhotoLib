//
//  CLViewController.m
//  CLPhotoLib
//
//  Created by claudeli@yeah.net on 10/15/2018.
//  Copyright (c) 2018 claudeli@yeah.net. All rights reserved.
//

#import "CLViewController.h"
#import <CLPhotoLib/CLPhotoLib.h>

@interface CLViewController ()<CLPickerRootControllerDelegate>

@end

@implementation CLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)clickPicker:(id)sender {
    CLPickerRootController *picker = [[CLPickerRootController alloc] init];
    picker.pickerDelegate = self;
    picker.allowAutorotate = YES;
    picker.allowPanGestureSelect = YES;
    picker.minDuration = 3.0f;
    picker.maxDuration = 60.0f;
    [self presentViewController:picker animated:YES completion:nil];
}
    
    // images
- (void)clPickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos assets:(NSArray *)assets{
    NSLog(@"========== %@", photos);
}
    
    // video
- (void)clPickerController:(CLPickerRootController *)picker didFinishPickingVideoCover:(UIImage *)videoCover videoURL:(NSURL *)videoURL{
    NSLog(@"========== %@", videoURL);
}
    
    // Cancel Picker
- (void)clPickerControllerDidCancel:(CLPickerRootController *)picker{
    NSLog(@"========== Cancel ==========");
}
    
    // User can write Custom video camera.
- (void)clPickerControllerDidShootVideo:(CLPickerRootController *)picker{
    NSLog(@"========== ShootVideo ==========");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
