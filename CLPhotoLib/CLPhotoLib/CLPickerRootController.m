//
//  CLPickerRootController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPickerRootController.h"
#import "CLPhotosViewController.h"
#import "CLConfig.h"
#import "CLProgressHUD.h"
#import "CLExtHeader.h"

@interface CLPickerRootController ()<CLVideoProcessingDelegate>{
    NSTimer *_timer;
    BOOL    _canRotate;
}

@property (nonatomic, strong) UILabel *tipLable;

@property (nonatomic, strong) CLProgressHUD *progressHUD;

@property (nonatomic, strong) CLEditManager *editManager;

@end

@implementation CLPickerRootController

- (instancetype)init{
    CLAlbumPickerController *albumPickerVc = [[CLAlbumPickerController alloc] init];
    self = [super initWithRootViewController:albumPickerVc];
    if (self) {
        self.backgroundColor = _backgroundColor?:[UIColor whiteColor];
        self.titleColor = _titleColor?:[UIColor whiteColor];
        self.navigationItemColor = _navigationItemColor?:CLBarItemTitleDefaultColor;
        self.minSize = CGSizeMake(750.0f, 750.0f);
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            self.columnCount = 5;
        } else {
            self.columnCount = 3;
        }
        self.minimumLineSpacing = 1.0f;
        self.minimumInteritemSpacing = 1.0f;
        self.sectionInset = UIEdgeInsetsMake(1.0f, 0, 1.0f, 0);
        
        self.maxSelectCount             = 9;
        self.maxDuration                = MAXFLOAT;
        self.outputVideoScale           = CLVideoOutputScale;
        self.allowEditVideo             = YES;
        self.allowAlbumDropDown         = NO;
        self.allowPanGestureSelect      = YES;
        self.allowImgMultiple           = YES;
        self.presetName                 = AVAssetExportPresetMediumQuality;
        
        self.allowPreviewImage          = YES;
        self.allowEditImage             = NO;
        self.allowSelectOriginalImage   = NO;
        self.allowDoneOnToolBar         = YES;
        
        self.allowSelectGif         = YES;
        self.allowSelectLivePhoto   = YES;
        self.allowTakePhoto         = YES;
        self.sortAscending          = NO;
        self.showCaptureOnCell      = NO;
        
        self.selectMode = CLPickerSelectModeMixDisplay;
        
        if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
            self.tipLable.hidden = NO;
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:YES];
        }else{
            [self gotoPhotosViewController];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.previousStatusBarStyle = UIStatusBarStyleLightContent;
    self.statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationColor = [UIColor darkGrayColor]; 
    self.navigationBar.translucent = YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self clearTimer];
    [UIApplication sharedApplication].statusBarStyle = self.previousStatusBarStyle;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle{
    _statusBarStyle = statusBarStyle;
    if (_navigationColor) {
        self.navigationBar.barStyle = _statusBarStyle?UIBarStyleBlack:UIBarStyleDefault;
    }
    [UIApplication sharedApplication].statusBarStyle = _statusBarStyle;
}

- (void)setNavigationColor:(UIColor *)navigationColor{
    _navigationColor = navigationColor;
    [self.navigationBar setBackgroundImage:[UIImage imageWithColor:_navigationColor] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
}

- (void)setNavigationBarImage:(UIImage *)navigationBarImage{
    [self.navigationBar setBackgroundImage:navigationBarImage forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
}

- (void)setNavigationItemColor:(UIColor *)navigationItemColor{
    _navigationItemColor = navigationItemColor;
    self.navigationBar.tintColor = _navigationItemColor;
}

- (void)setTitleColor:(UIColor *)titleColor{
    _titleColor = titleColor;
    self.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObject:_titleColor forKey:NSForegroundColorAttributeName];
}

- (void)setMinSize:(CGSize)minSize{
    _minSize = minSize;
    CLMinSize = minSize;
}

- (void)setAllowSelectGif:(BOOL)allowSelectGif{
    _allowSelectGif = allowSelectGif;
    CLAllowSelectGif = _allowSelectGif;
}

- (void)setAllowSelectLivePhoto:(BOOL)allowSelectLivePhoto{
    _allowSelectLivePhoto = allowSelectLivePhoto;
    CLAllowSelectLivePhoto = _allowSelectLivePhoto;
}

- (void)setSortAscending:(BOOL)sortAscending{
    _sortAscending = sortAscending;
    CLSortAscending = _sortAscending;
}
- (void)setSelectedAssets:(NSArray *)selectedAssets{
    _selectedAssets = selectedAssets;
    for (id asset in _selectedAssets) {
        CLPhotoModel *model = [CLPhotoModel modelWithAsset:asset];
        model.isSelected = YES;
        [self.selectedModels addObject:model];
    }
}

- (NSMutableArray<CLPhotoModel *> *)selectedModels{
    if (!_selectedModels) {
        _selectedModels = [NSMutableArray array];
    }
    return _selectedModels;
}

-(BOOL)shouldAutorotate{
    return self.allowAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (self.allowAutorotate) {
        return UIInterfaceOrientationMaskAll;
    }
    else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return [self.viewControllers.lastObject preferredInterfaceOrientationForPresentation];
}

- (void)observeAuthrizationStatusChange {
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [self gotoPhotosViewController];
        [self clearTimer];
    }
}

- (void)clearTimer{
    if (_timer) {
        [_tipLable removeFromSuperview];
        _tipLable = nil;
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)gotoPhotosViewController{
    CLPhotosViewController *imagePicker = [[CLPhotosViewController alloc] init];
    [self showViewController:imagePicker sender:nil];
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UILabel *)tipLable{
    if (!_tipLable) {
        _tipLable = [[UILabel alloc] init];
        _tipLable.textAlignment = NSTextAlignmentCenter;
        _tipLable.numberOfLines = 0;
        _tipLable.font = [UIFont systemFontOfSize:16];
        _tipLable.textColor = [UIColor blackColor];
        _tipLable.adjustsFontSizeToFitWidth = YES;
        _tipLable.text = [NSString stringWithFormat:CLString(@"CLText_NotAccessAlbumTip"), [UIDevice currentDevice].model, CLAppName];
        [self.view addSubview:_tipLable];
    }
    return _tipLable;
}

- (CLProgressHUD *)progressHUD{
    if (!_progressHUD) {
        _progressHUD = [[CLProgressHUD alloc] init];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (CLEditManager *)editManager{
    if (!_editManager) {
        _editManager = [[CLEditManager alloc] init];
        _editManager.delegate = self;
    }
    return _editManager;
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    _tipLable.frame = CGRectMake(15, self.view.height/4.0, self.view.width - 30, 60);
}

#pragma mark -
#pragma mark -- Public Methods --
- (void)showText:(NSString *)text{
    [self.progressHUD showText:text];
}

- (void)showText:(NSString *)text delay:(NSTimeInterval)delay{
    [self.progressHUD showText:text delay:delay];
}

- (void)showProgress{
    [self.progressHUD showProgress:NO];
}

- (void)showProgressWithText:(NSString *)text{
    [self.progressHUD showProgressWithText:text];
}

- (void)hideProgress{
    [self.progressHUD hideProgress];
}

- (void)clickCancelAction{
    cl_weakSelf(self);
    [self dismissViewControllerAnimated:YES completion:^{
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if ([strongSelf.pickerDelegate respondsToSelector:@selector(clPickerControllerDidCancel:)]) {
            [strongSelf.pickerDelegate clPickerControllerDidCancel:strongSelf];
        }
        if (strongSelf.pickerCancelHandle) {
            strongSelf.pickerCancelHandle();
        }
    }];
}

- (void)clickShootVideoAction{
    cl_weakSelf(self);
    [self dismissViewControllerAnimated:YES completion:^{
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if ([strongSelf.pickerDelegate respondsToSelector:@selector(clPickerControllerDidShootVideo:)]) {
            [strongSelf.pickerDelegate clPickerControllerDidShootVideo:strongSelf];
        }
        if (strongSelf.pickerShootVideoHandle) {
            strongSelf.pickerShootVideoHandle();
        }
    }];
}

- (void)didFinishPickingPhotosAction{
    [self showProgress];
    cl_weakSelf(self);
    [CLPhotoShareManager requestImagesWithModelArray:self.selectedModels isOriginal:self.selectedOriginalImage completion:^(NSArray<UIImage *> *photos, NSArray *assets) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        [strongSelf hideProgress];
        [strongSelf dismissViewControllerAnimated:YES completion:^{
            if ([strongSelf.pickerDelegate respondsToSelector:@selector(clPickerController:didFinishPickingPhotos:assets:)]) {
                [strongSelf.pickerDelegate clPickerController:strongSelf didFinishPickingPhotos:photos assets:assets];
            }
            if (strongSelf.pickingPhotosHandle) {
                strongSelf.pickingPhotosHandle(photos, assets);
            }
        }];
    }];
}

- (void)clickPickingVideoActionForAsset:(AVAsset *)asset range:(CMTimeRange)range{
    _canRotate = self.allowAutorotate;
    self.allowAutorotate = NO;
    [self.editManager exportEditVideoForAsset:asset
                                        range:range
                                    sizeScale:self.outputVideoScale
                              isDistinguishWH:self.isDistinguishWH
                                      cutMode:CLVideoCutModeScaleAspectFit
                                    fillColor:CLVideoFillColor
                                   presetName:self.presetName];
}

- (void)cancelExport{
    if (_editManager) {
        [_editManager cancelExport];
    }
}

- (void)didFinishPickingVideoCover:(UIImage *)videoCover videoURL:(NSURL *)videoURL{
    cl_weakSelf(self);
    [self dismissViewControllerAnimated:YES completion:^{
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if ([strongSelf.pickerDelegate respondsToSelector:@selector(clPickerController:didFinishPickingVideoCover:videoURL:)]) {
            [strongSelf.pickerDelegate clPickerController:strongSelf didFinishPickingVideoCover:videoCover videoURL:videoURL];
        }
        if (strongSelf.pickingVideoHandle) {
            strongSelf.pickingVideoHandle(videoCover, videoURL);
        }
    }];
}

#pragma mark -
#pragma mark -- CLVideoProcessingDelegate --
- (void)editManager:(CLEditManager *)editManager didFinishedOutputURL:(NSURL *)outputURL{
    UIImage *cover = [CLEditManager requestThumbnailImageForAVAsset:[AVAsset assetWithURL:outputURL] timeBySecond:0];
    [self hideProgress];
    if (_canRotate) {
        self.allowAutorotate = _canRotate;
    }
    [self didFinishPickingVideoCover:cover videoURL:outputURL];
    /*
     [CLPhotoManager saveVideoToAblum:outputURL completion:^(BOOL success, PHAsset *asset) {
        if (success) {
            CLLog(@"保存到本地相册");
        }
     }];
     */
}

-(void)editManager:(CLEditManager *)editManager handlingProgress:(CGFloat)progress{
    [self showProgressWithText:[NSString stringWithFormat:@"%@ %.0f%%", CLString(@"CLText_Processing"), (progress * 100.0)]];
}

-(void)editManager:(CLEditManager *)editManager operationFailure:(NSError *)error{
    if (_canRotate) {
        self.allowAutorotate = _canRotate;
    }
    [self showText:error.localizedDescription];
}

-(void)dealloc{
    CLLog(@"%s", __func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

#import "CLAlbumTableView.h"
#import "CLPhotoModel.h"
@interface CLAlbumPickerController (){
    BOOL _reload;
}

@property (nonatomic, strong) CLAlbumTableView *tableView;

@end

@implementation CLAlbumPickerController

- (CLAlbumTableView *)tableView{
    if (!_tableView) {
        _tableView = [[CLAlbumTableView alloc] init];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.tableColor = [UIColor whiteColor];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (CLPickerRootController *)picker{
    return (CLPickerRootController *)self.navigationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeTop;
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = CLString(@"CLText_Ablum");
    self.tableView.hidden = NO;
    cl_WS(ws);
    [_tableView setDidSelectAlbumBlock:^(CLAlbumModel *model) {
        [ws pushImagePickerWithModel:model];
    }];
    [self _initRightItem];
    if (![NSBundle clLocalizedBundle]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Not Found\n CLPhotoLib.bundle" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAlbumList) name:CLPhotoLibReloadAlbumList object:nil];
}

- (void)reloadAlbumList{
    _reload = YES;
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [UIApplication sharedApplication].statusBarHidden = self.navigationController.navigationBar.hidden;
    _tableView.frame = self.view.bounds;
    [_tableView showAlbumAnimated:NO];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (_reload || !_tableView.albumArray) {
        _reload = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            cl_weakSelf(self);
            [CLPhotoShareManager getAlbumListWithSelectMode:self.picker.selectMode completion:^(NSArray<CLAlbumModel *> *models) {
                cl_strongSelf(weakSelf);
                if (strongSelf) {
                    for (CLAlbumModel *albumModel in models) {
                        albumModel.selectedModels = strongSelf.picker.selectedModels;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.tableView.albumArray = models;
                    });
                }
            }];
        });
    }else{
        for (CLAlbumModel *albumModel in _tableView.albumArray) {
            albumModel.selectedModels = self.picker.selectedModels;
        }
        [_tableView reloadData];
    }
}

- (void)_initRightItem{
    UIButton *rightItem = [UIButton buttonWithType:UIButtonTypeCustom];
    rightItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    CGFloat width = GetMatchValue(CLString(@"CLText_Cancel"), CLNavigationItemFontSize, YES, self.navigationController.navigationBar.height);
    rightItem.frame = CGRectMake(0, 0, width, self.navigationController.navigationBar.height);
    rightItem.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
    [rightItem setTitle:CLString(@"CLText_Cancel") forState:UIControlStateNormal];
    rightItem.titleLabel.adjustsFontSizeToFitWidth = YES;
    [rightItem setTitleColor:self.picker.navigationItemColor forState:UIControlStateNormal];
    [rightItem addTarget:self action:@selector(clickRightItemAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
}

- (void)clickRightItemAction{
    [self.picker clickCancelAction];
}

- (void)pushImagePickerWithModel:(CLAlbumModel *)model{
    CLPhotosViewController *imagePicker = [[CLPhotosViewController alloc] init];
    imagePicker.albumModel = model;
    [self.navigationController showViewController:imagePicker sender:self];
}

- (void)dealloc{
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

