//
//  CLEditImageController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/23.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLEditImageController.h"
#import "CLPickerRootController.h"
#import "CLExtHeader.h"
#import "CLConfig.h"

@interface CLEditImageController ()

@end

@implementation CLEditImageController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:CLString(@"CLText_NotSupport") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:CLString(@"CLText_OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert addAction:action];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = self.view.bounds;
        [self presentViewController:alert animated:YES completion:nil];
    }else{
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (CLPickerRootController *)picker{
    return (CLPickerRootController *)self.navigationController;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
