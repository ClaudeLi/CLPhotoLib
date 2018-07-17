//
//  CLPhotoViewController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPhotosViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "CLConfig.h"
#import "CLPhotoCollectionCell.h"
#import "CLPickerToolBar.h"
#import "CLAlbumTableView.h"
#import "CLPreviewViewController.h"
#import "CLTouchViewController.h"
#import "CLEditImageController.h"
#import "CLExtHeader.h"

NSNotificationName const CLPhotoLibReloadAlbumList = @"CLPhotoLibReloadAlbumList";

static NSString *takeIdentifier = @"CLTakePhotoCellIdentifier";
static NSString *itemIdentifier = @"CLPhotoCollectionCellIdentifier";

@interface CLImagePickerController : UIImagePickerController

@end

@implementation CLImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

@end

typedef NS_ENUM(NSInteger, CLSlideSelectType) {
    CLSlideSelectTypeNone     = 0,
    CLSlideSelectTypeSelect,
    CLSlideSelectTypeCancel,
};

@interface CLPhotosViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    BOOL _reloadAlbumList;
    // 开始滑动选择 或 取消
    BOOL _beginSelect;
    // 滑动选择 或 取消
    CLSlideSelectType _selectType;
    // 开始滑动的indexPath
    NSIndexPath     *_beginSlideIndexPath;
    // 最后滑动经过的index，开始的indexPath不计入，优化拖动手势计算，避免单个cell中冗余计算多次
    NSInteger       _lastSlideIndex;
}

@property (nonatomic, strong) UIButton          *titleBtn;
@property (nonatomic, strong) CLAlbumTableView  *albumView;
@property (nonatomic, strong) CLDoneButton      *doneBtn;

@property (nonatomic, strong) UICollectionView  *collectionView;
@property (nonatomic, strong) CLPickerToolBar   *toolBar;

@property (nonatomic, strong) NSMutableArray <CLPhotoModel *> *photoArray;

// 所有滑动经过的indexPath
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *arrSlideIndexPath;
// 所有滑动经过的indexPath的初始选择状态
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *dicOriSelectStatus;
@end

@implementation CLPhotosViewController

#pragma mark -
#pragma mark -- Life Cycle Methods --
- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.picker.selectMode != CLPickerSelectModeAllowVideo && self.picker.allowImgMultiple) {
        if (self.picker.allowPreviewImage ||
            self.picker.allowEditImage ||
            self.picker.allowSelectOriginalImage ||
            self.picker.allowDoneOnToolBar) {
            self.toolBar.hidden = NO;
        }
    }
    [self _initNavigationItems];
    self.view.backgroundColor = self.picker.backgroundColor;
    self.collectionView.backgroundColor = self.picker.backgroundColor;
    if (self.picker.allowPanGestureSelect && self.picker.selectMode != CLPickerSelectModeAllowVideo) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        [self.view addGestureRecognizer:pan];
    }
    [self _initData];
    if (![NSBundle clLocalizedBundle]) {
        [self.picker showText:@"Not Found\n CLPhotoLib.bundle"];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = self.picker.statusBarStyle;
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [UIApplication sharedApplication].statusBarHidden = self.navigationController.navigationBar.hidden;
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        inset = self.view.safeAreaInsets;
    }
    _toolBar.frame = CGRectMake(0, self.view.height - CLToolBarHeight - inset.bottom, self.view.width, CLToolBarHeight + inset.bottom);
    
    CGFloat width = self.view.width - inset.left - inset.right;
    _collectionView.frame = CGRectMake(inset.left, 0, width, self.view.height);
    if (_albumView) {
        CGFloat topHeight = ([UIApplication sharedApplication].statusBarHidden?0:[[UIApplication sharedApplication] statusBarFrame].size.height) + self.navigationController.navigationBar.height;
        _albumView.frame = CGRectMake(0, topHeight, self.view.width, self.view.height - topHeight);
    }
}

- (void)setTitle:(NSString *)title{
    if (self.picker.allowAlbumDropDown) {
        if (_titleBtn.hidden) {
            _titleBtn.hidden = NO;
        }
        [_titleBtn setTitle:title forState:UIControlStateNormal];
        [self _updateTitleBtnLayout];
    }else{
        [super setTitle:title];
    }
}

#pragma mark -
#pragma mark -- self Methods --
- (void)_initNavigationItems{
    if (self.picker.allowDoneOnToolBar) {
        UIButton *rightItem = [UIButton buttonWithType:UIButtonTypeCustom];
        rightItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        CGFloat width = GetMatchValue(CLString(@"CLText_Cancel"), CLNavigationItemFontSize, YES, self.navigationController.navigationBar.height);
        rightItem.frame = CGRectMake(0, 0, width, self.navigationController.navigationBar.height);
        rightItem.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
        [rightItem setTitle:CLString(@"CLText_Cancel") forState:UIControlStateNormal];
        [rightItem setTitleColor:self.picker.navigationItemColor forState:UIControlStateNormal];
        [rightItem addTarget:self action:@selector(clickCancelItemAction) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightItem];
    }else{
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.doneBtn];
    }
    if (self.picker.allowAlbumDropDown) {
        UIButton *leftItem = [UIButton buttonWithType:UIButtonTypeCustom];
        leftItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        leftItem.frame = CGRectMake(0, 0, self.navigationController.navigationBar.height, self.navigationController.navigationBar.height);
        [leftItem setImage:[UIImage imageNamedFromBundle:@"btn_backItem_icon"] forState:UIControlStateNormal];
        [leftItem addTarget:self action:@selector(clickCancelItemAction) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem  = [[UIBarButtonItem alloc] initWithCustomView:leftItem];
        
        self.navigationItem.titleView = self.titleBtn;
        self.albumView.hidden = YES;
    }
}

- (void)_initData{
    if (_albumModel) {
        self.title = self.albumModel.title;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.photoArray = _albumModel.models.mutableCopy;
            dispatch_async(dispatch_get_main_queue(), ^{
                [_collectionView reloadData];
                [self scrollToBottom];
            });
        });
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            cl_weakSelf(self);
            [CLPhotoShareManager getCameraRollAlbumWithSelectMode:self.picker.selectMode complete:^(CLAlbumModel *albumModel) {
                cl_strongSelf(weakSelf);
                if (strongSelf) {
                    strongSelf.albumModel = albumModel;
                    strongSelf.photoArray = albumModel.models.mutableCopy;
                    [self checkSelectedModels];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.title = albumModel.title;
                        [strongSelf.collectionView reloadData];
                        [strongSelf scrollToBottom];
                    });
                }
            }];
        });
    }
}

- (void)checkSelectedModels {
    for (CLPhotoModel *model in self.photoArray) {
        if (!model.isSelected){
            for (PHAsset *asset in self.picker.selectedAssets) {
                if ([asset.localIdentifier isEqualToString:model.asset.localIdentifier]){
                    model.isSelected = YES;
                    if (![CLPhotoManager checkSelcectedWithModel:model identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:self.picker.selectedModels]]) {
                        [self.picker.selectedModels addObject:model];
                    }
                }
            }
        }
    }
}

#pragma mark -
#pragma mark -- UICollectionViewDataSource & UICollectionViewDelegate --
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.picker.allowTakePhoto) {
        return _photoArray.count + 1;
    }
    return _photoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (_photoArray && self.picker.allowTakePhoto && ((self.picker.sortAscending && indexPath.row >= _photoArray.count) || (!self.picker.sortAscending && indexPath.row == 0))) {
        CLTakePhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:takeIdentifier forIndexPath:indexPath];
        cell.allowSelectVideo = self.picker.selectMode == CLPickerSelectModeAllowVideo ? YES:NO;
        cell.showCaptureOnCell = self.picker.showCaptureOnCell;
        return cell;
    }
    CLPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemIdentifier forIndexPath:indexPath];
    cell.allowImgMultiple = self.picker.allowImgMultiple;
    CLPhotoModel *model;
    if (!self.picker.allowTakePhoto || self.picker.sortAscending) {
        if (_photoArray.count > indexPath.row) {
            model = _photoArray[indexPath.row];
        }
    } else {
        if (_photoArray.count > (indexPath.row - 1)) {
            model = _photoArray[indexPath.row-1];
        }
    }
    cl_weakSelf(self);
    cl_weakify(cell, weakCell);
    [cell setDidSelectPhotoBlock:^(BOOL isSelected) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        cl_strongify(weakCell, strongCell);
        if (isSelected) {
            strongCell.selectBtnSelect = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:strongSelf.picker.selectedModels];
            [selectedModels enumerateObjectsUsingBlock:^(CLPhotoModel  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([model.asset.localIdentifier isEqualToString:obj.asset.localIdentifier]) {
                    [strongSelf.picker.selectedModels removeObject:obj];
                    [strongSelf refreshBottomToolBarStatus];
                }
            }];
        } else {
            // 2. select:check if over the maxCount
            if (strongSelf.picker.selectedModels.count < strongSelf.picker.maxSelectCount) {
                strongCell.selectBtnSelect = YES;
                model.isSelected = YES;
                if (![CLPhotoManager checkSelcectedWithModel:model identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:strongSelf.picker.selectedModels]]) {
                    [strongSelf.picker.selectedModels addObject:model];
                    [strongSelf refreshBottomToolBarStatus];
                }
            } else {
                [strongSelf.picker showText:[NSString stringWithFormat:CLString(@"CLText_MaxImagesCount"), strongSelf.picker.maxSelectCount]];
            }
        }
    }];
    if (model) {
        cell.model = model;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ((self.picker.sortAscending && indexPath.row >= _photoArray.count) || (!self.picker.sortAscending && indexPath.row == 0 && self.picker.allowTakePhoto)) {
        if (self.picker.selectMode == CLPickerSelectModeAllowVideo) {
            [self takeVideo];
            return;
        }else{
            if (self.picker.selectedModels.count < self.picker.maxSelectCount) {
                [self takePhoto];
            }else{
                [self.picker showText:[NSString stringWithFormat:CLString(@"CLText_MaxImagesCount"), self.picker.maxSelectCount]];
            }
            return;
        }
    }
    NSInteger index = indexPath.row;
    if (self.picker.allowTakePhoto && !self.picker.sortAscending) {
        index = indexPath.row - 1;
    }
    if (index < _photoArray.count) {
        [self gotoPreviewController:index modelArray:_photoArray];
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return self.picker.minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return self.picker.minimumInteritemSpacing;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGFloat width = MIN(collectionView.width, collectionView.height);
    CGFloat itemWidth = (width - self.picker.sectionInset.left - self.picker.sectionInset.right - self.picker.columnCount * self.picker.minimumInteritemSpacing)/(self.picker.columnCount * 1.0);
    return CGSizeMake(itemWidth, itemWidth);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    UIEdgeInsets inset = self.picker.sectionInset;
    if (@available(iOS 11, *)) {
        inset.bottom += self.view.safeAreaInsets.bottom;
    }
    if (_toolBar) {
        inset.bottom += CLToolBarHeight;
    }
    return inset;
}

#pragma mark -
#pragma mark -- Private Methods --
- (void)_updateTitleBtnLayout{
    CGFloat imageWith = _titleBtn.imageView.frame.size.width;
    CGFloat labelWidth = _titleBtn.titleLabel.frame.size.width;
    _titleBtn.imageEdgeInsets = UIEdgeInsetsMake(0, labelWidth + 10, 0, -labelWidth - 10);
    _titleBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -imageWith + 10, 0, imageWith - 10);
}

- (void)scrollToBottom{
    if (!self.picker.sortAscending) {
        return;
    }
    if (_photoArray.count > 0) {
        NSInteger index = _photoArray.count - 1;
        if (self.picker.allowTakePhoto) {
            index += 1;
        }
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
}

- (void)refreshBottomToolBarStatus{
    if (_toolBar) {
        if (self.picker.allowPreviewImage) {
            _toolBar.previewBtn.selected = self.picker.selectedModels.count > 0;
        }
        if (self.picker.allowEditImage) {
            _toolBar.editBtn.selected = self.picker.selectedModels.count == 1;
        }
        if (self.picker.allowSelectOriginalImage) {
            _toolBar.originalBtn.selected = self.picker.selectedOriginalImage;
            if (self.picker.selectedModels.count) {
                if (_toolBar.originalBtn.selected) {
                    [self getOriginalImageBytes];
                }else{
                    [_toolBar.originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
                }
            }else{
                [_toolBar.originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
            }
        }
        if (self.picker.allowDoneOnToolBar) {
            _toolBar.doneBtn.number = self.picker.selectedModels.count;
        }
    }
    if (_doneBtn) {
        _doneBtn.number = self.picker.selectedModels.count;
    }
}

- (void)getOriginalImageBytes{
    if (_selectType) {
        return;
    }
    [_toolBar startAnimating];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        cl_weakSelf(self);
        [CLPhotoManager getPhotosBytesWithArray:self.picker.selectedModels completion:^(NSString *photosBytes) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            [strongSelf performSelector:@selector(setOriginalImageBytes:) withObject:photosBytes afterDelay:0.2];
        }];
    });
}

- (void)setOriginalImageBytes:(id)object{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_toolBar stopAnimating];
        [_toolBar.originalBtn setTitle:[NSString stringWithFormat:@"%@(%@)", CLString(@"CLText_Original"), object] forState:UIControlStateNormal];
    });
}

- (void)gotoPreviewController:(NSInteger)index modelArray:(NSArray *)modelArray{
    cl_WS(ws);
    CLPreviewViewController *preview = [[CLPreviewViewController alloc] init];
    preview.currentIndex = index;
//        preview.currentModel = modelArray[index];
    preview.photoArray = modelArray;
    [preview setDidReloadToolBarStatus:^(BOOL reload){
        if (reload) {
            [ws.collectionView reloadData];
        }
        [ws refreshBottomToolBarStatus];
    }];
    [self.navigationController pushViewController:preview animated:YES];
}

- (void)takePhoto {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // 无权限 做一个友好的提示
    if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) {
        [self showAlertWithMessage:CLString(@"CLText_NotAccessCamera")];
        return;
    }
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        CLImagePickerController *imageCamera = [[CLImagePickerController alloc] init];
        imageCamera.delegate = self;
        imageCamera.sourceType = UIImagePickerControllerSourceTypeCamera;
//        imageCamera.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self showDetailViewController:imageCamera sender:self];
    }else{
        [self.picker showText:CLString(@"CLText_CannotSimulatorCamera")];
    }
}

- (void)takeVideo{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        cl_weakSelf(self);
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            if (granted) {
                // Microphone is enabled
                if (authorizationStatus == AVAuthorizationStatusRestricted|| authorizationStatus == AVAuthorizationStatusDenied){
                    [strongSelf showAlertWithMessage:CLString(@"CLText_NotAccessCamera")];
                }else{
                    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
                        if (strongSelf.picker.usedCustomRecording) {
                            [strongSelf.picker clickShootVideoAction];
                        }else{
                            CLImagePickerController *imageCamera = [[CLImagePickerController alloc] init];
                            imageCamera.delegate = strongSelf;
//                            imageCamera.allowsEditing = YES;
                            imageCamera.mediaTypes = @[(NSString*)kUTTypeMovie];
                            imageCamera.videoQuality = UIImagePickerControllerQualityTypeIFrame960x540;
                            imageCamera.sourceType = UIImagePickerControllerSourceTypeCamera;
                            imageCamera.videoMaximumDuration = strongSelf.picker.maxDuration;
                            [strongSelf showDetailViewController:imageCamera sender:strongSelf];
                        }
                    }else{
                        [strongSelf.picker showText:CLString(@"CLText_CannotSimulatorCamera")];
                    }
                }
            }else {
                // Microphone disabled code
                [strongSelf showAlertWithMessage:CLString(@"CLText_NotAccessMicrophone")];
            }
        }];
    }
}

- (void)showAlertWithMessage:(NSString *)message{
    message = [NSString stringWithFormat:message, [UIDevice currentDevice].model, CLAppName];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:CLString(@"CLText_GotoSettings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
        } else {
            if ([[UIApplication sharedApplication] canOpenURL:URL]) {
                [[UIApplication sharedApplication] openURL:URL];
            }
        }
    }];
    [alert addAction:action];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:CLString(@"CLText_OK") style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
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
#pragma mark -- UIImagePickerControllerDelegate --
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    cl_WS(ws);
    [picker dismissViewControllerAnimated:YES completion:^{
        NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
        if ([type isEqualToString:@"public.image"]) {
            [ws.picker showProgress];
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            cl_weakSelf(self);
            [CLPhotoManager saveImageToAblum:image completion:^(BOOL success, PHAsset *asset) {
                cl_strongSelf(weakSelf);
                if (!strongSelf) {
                    return;
                }
                if (success) {
                    strongSelf->_reloadAlbumList = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:CLPhotoLibReloadAlbumList object:nil];
                    if (strongSelf) {
                        [strongSelf reloadPhotoArray:NO];
                    }
                }else{
                    [strongSelf.picker showText:CLString(@"CLText_SaveImageError")];
                }
            }];
        }else if ([type isEqualToString:@"public.movie"]) {
            [ws.picker showProgress];
            NSURL *URL = [info objectForKey:UIImagePickerControllerMediaURL];
            cl_weakSelf(self);
            [CLPhotoManager saveVideoToAblum:URL completion:^(BOOL success, PHAsset *asset) {
                cl_strongSelf(weakSelf);
                if (!strongSelf) {
                    return;
                }
                if (success) {
                    strongSelf->_reloadAlbumList = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:CLPhotoLibReloadAlbumList object:nil];
                    if (strongSelf) {
                        [strongSelf reloadPhotoArray:YES];
                    }
                }else{
                    [strongSelf.picker showText:CLString(@"CLText_SaveVideoError")];
                }
            }];
        }
    }];
}

- (void)reloadPhotoArray:(BOOL)isVideo{
    cl_weakSelf(self);
    __block BOOL _isVideo = isVideo;
    [CLPhotoShareManager getCameraRollAlbumWithSelectMode:self.picker.selectMode complete:^(CLAlbumModel *albumModel) {
        cl_strongSelf(weakSelf);
        if (strongSelf) {
            strongSelf.albumModel = albumModel;
            CLPhotoModel *model;
            if (strongSelf.picker.sortAscending) {
                if (albumModel.models.count) {
                    model = [albumModel.models lastObject];
                    [strongSelf.photoArray addObject:model];
                }
            } else {
                if (albumModel.models.count) {
                    model = [albumModel.models firstObject];
                    [strongSelf.photoArray insertObject:model atIndex:0];
                }
            }
            if (!_isVideo) {
                if (strongSelf.picker.selectedModels.count < strongSelf.picker.maxSelectCount) {
                    if (model) {
                        model.isSelected = YES;
                        [strongSelf.picker.selectedModels addObject:model];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [strongSelf refreshBottomToolBarStatus];
                        });
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf.picker hideProgress];
                [strongSelf.collectionView reloadData];
                [strongSelf scrollToBottom];                
            });
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)clickCancelItemAction{
    [self.picker clickCancelAction];
}

- (void)clickDoneItemAction{
    [self.picker didFinishPickingPhotosAction];
}

- (void)clickEidtImageAction{
    if (self.picker.selectedModels.count) {
        CLEditImageController *image = [[CLEditImageController alloc] init];
        image.model = self.picker.selectedModels[0];
        [self.navigationController pushViewController:image animated:NO];
    }
}

- (void)clickTitleViewAction:(UIButton *)sender{
    if (!sender.selected) {
        if (_reloadAlbumList || !_albumView.albumArray) {
            _reloadAlbumList = NO;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                cl_weakSelf(self);
                [CLPhotoShareManager getAlbumListWithSelectMode:self.picker.selectMode completion:^(NSArray<CLAlbumModel *> *models) {
                    cl_strongSelf(weakSelf);
                    if (!strongSelf) {
                        return;
                    }
                    for (CLAlbumModel *albumModel in models) {
                        albumModel.selectedModels = strongSelf.picker.selectedModels;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        strongSelf.albumView.albumArray = models;
                        [strongSelf.albumView showAlbumAnimated:YES];
                        [UIView animateWithDuration:CLLittleControlAnimationTime animations:^{
                            CGAffineTransform transform = strongSelf.titleBtn.imageView.transform;
                            CGAffineTransform transform2 =  CGAffineTransformRotate(transform, M_PI);
                            [strongSelf.titleBtn.imageView setTransform:transform2];
                        } completion:^(BOOL finished) {
                        }];
                    });
                }];
            });
        }else{
            for (CLAlbumModel *albumModel in self.albumView.albumArray) {
                albumModel.selectedModels = self.picker.selectedModels;
            }
            [self.albumView showAlbumAnimated:YES];
            [self.albumView reloadData];
            [UIView animateWithDuration:CLLittleControlAnimationTime animations:^{
                CGAffineTransform transform = self.titleBtn.imageView.transform;
                CGAffineTransform transform2 =  CGAffineTransformRotate(transform, M_PI);
                [self.titleBtn.imageView setTransform:transform2];
            } completion:^(BOOL finished) {
            }];
        }
    }else{
        [_albumView dismiss];
    }
    sender.selected = !sender.selected;
}

- (void)panAction:(UIPanGestureRecognizer *)pan{
    CGPoint point = [pan locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) {
        return;
    }
    BOOL asc = !self.picker.allowTakePhoto || self.picker.sortAscending;
    if (pan.state == UIGestureRecognizerStateBegan) {
        _beginSelect = !indexPath ? NO : ![cell isKindOfClass:CLTakePhotoCell.class];
        if (_beginSelect) {
            NSInteger index = asc ? indexPath.row : indexPath.row-1;
            if (index < self.photoArray.count) {
                CLPhotoModel *m = self.photoArray[index];
                _selectType = m.isSelected ? CLSlideSelectTypeCancel : CLSlideSelectTypeSelect;
                _beginSlideIndexPath = indexPath;
                if (!m.isSelected && m.type != CLAssetMediaTypeVideo) {
                    // 2. select:check if over the maxCount
                    if (self.picker.selectedModels.count < self.picker.maxSelectCount) {
                        m.isSelected = YES;
                        if (![CLPhotoManager checkSelcectedWithModel:m identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:self.picker.selectedModels]]) {
                            [self.picker.selectedModels addObject:m];
                        }
                    } else {
                        [self.picker showText:[NSString stringWithFormat:CLString(@"CLText_MaxImagesCount"), self.picker.maxSelectCount]];
                        return;
                    }
                } else if (m.isSelected) {
                    m.isSelected = NO;
                    for (CLPhotoModel *sm in self.picker.selectedModels) {
                        if ([sm.asset.localIdentifier isEqualToString:m.asset.localIdentifier]) {
                            [self.picker.selectedModels removeObject:sm];
                            break;
                        }
                    }
                }
                CLPhotoCollectionCell *c = (CLPhotoCollectionCell *)cell;
                c.selectBtnSelect = m.isSelected;
                [self refreshBottomToolBarStatus];
            }
        }
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        if (!_beginSelect ||
            !indexPath ||
            indexPath.row == _lastSlideIndex ||
            [cell isKindOfClass:CLTakePhotoCell.class] ||
            _selectType == CLSlideSelectTypeNone) return;
        
        _lastSlideIndex = indexPath.row;
        
        NSInteger minIndex = MIN(indexPath.row, _beginSlideIndexPath.row);
        NSInteger maxIndex = MAX(indexPath.row, _beginSlideIndexPath.row);
        
        BOOL minIsBegin = minIndex == _beginSlideIndexPath.row;
        
        for (NSInteger i = _beginSlideIndexPath.row;
             minIsBegin ? i<=maxIndex: i>= minIndex;
             minIsBegin ? i++ : i--) {
            if (i == _beginSlideIndexPath.row) continue;
            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:0];
            if (![self.arrSlideIndexPath containsObject:p]) {
                [self.arrSlideIndexPath addObject:p];
                NSInteger index = asc ? i : i-1;
                if (index < self.photoArray.count) {
                    CLPhotoModel *m = self.photoArray[index];
                    [self.dicOriSelectStatus setValue:@(m.isSelected) forKey:@(p.row).stringValue];
                }
            }
        }
        
        for (NSIndexPath *path in self.arrSlideIndexPath) {
            NSInteger index = asc ? path.row : path.row-1;
            if (index < self.photoArray.count) {
                //是否在最初和现在的间隔区间内
                BOOL inSection = path.row >= minIndex && path.row <= maxIndex;
                CLPhotoModel *m = self.photoArray[index];
                switch (_selectType) {
                    case CLSlideSelectTypeSelect: {
                        if (!m.isSelected && m.type != CLAssetMediaTypeVideo) {
                            // 2. select:check if over the maxCount
                            if (self.picker.selectedModels.count < self.picker.maxSelectCount) {
                                m.isSelected = YES;
                                if (![CLPhotoManager checkSelcectedWithModel:m identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:self.picker.selectedModels]]) {
                                    [self.picker.selectedModels addObject:m];
                                }
                            } else {
                                [self.picker showText:[NSString stringWithFormat:CLString(@"CLText_MaxImagesCount"), self.picker.maxSelectCount]];
                                return;
                            }
                        }
                    }
                        break;
                    case CLSlideSelectTypeCancel: {
                        if (inSection) m.isSelected = NO;
                    }
                        break;
                    default:
                        break;
                }
                if (!inSection) {
                    //未在区间内的model还原为初始选择状态
                    m.isSelected = [self.dicOriSelectStatus[@(path.row).stringValue] boolValue];
                }
                //判断当前model是否已存在于已选择数组中
                BOOL flag = NO;
                NSMutableArray *arrDel = [NSMutableArray array];
                for (CLPhotoModel *sm in self.picker.selectedModels) {
                    if ([sm.asset.localIdentifier isEqualToString:m.asset.localIdentifier]) {
                        if (!m.isSelected) {
                            [arrDel addObject:sm];
                        }
                        flag = YES;
                        break;
                    }
                }
                [self.picker.selectedModels removeObjectsInArray:arrDel];
                
                if (!flag && m.isSelected) {
                    [self.picker.selectedModels addObject:m];
                }
                CLPhotoCollectionCell *c = (CLPhotoCollectionCell *)[self.collectionView cellForItemAtIndexPath:path];
                c.selectBtnSelect = m.isSelected;
                [self refreshBottomToolBarStatus];
            }
        }
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled) {
        //清空临时属性及数组
        if (!self.arrSlideIndexPath.count && !self.dicOriSelectStatus.count) {
            _selectType = CLSlideSelectTypeNone;
            return;
        }
        _selectType = CLSlideSelectTypeNone;
        [self.arrSlideIndexPath removeAllObjects];
        [self.dicOriSelectStatus removeAllObjects];
        [self refreshBottomToolBarStatus];
    }
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (CLPickerRootController *)picker{
    return (CLPickerRootController *)self.navigationController;
}

- (NSMutableArray<NSIndexPath *> *)arrSlideIndexPath
{
    if (!_arrSlideIndexPath) {
        _arrSlideIndexPath = [NSMutableArray array];
    }
    return _arrSlideIndexPath;
}

- (NSMutableDictionary<NSString *, NSNumber *> *)dicOriSelectStatus
{
    if (!_dicOriSelectStatus) {
        _dicOriSelectStatus = [NSMutableDictionary dictionary];
    }
    return _dicOriSelectStatus;
}

- (UIButton *)titleBtn{
    if (!_titleBtn) {
        _titleBtn = [UIButton new];
        _titleBtn.frame = CGRectMake(0, 0, self.view.width - 160, self.navigationController.navigationBar.height);
        _titleBtn.contentHorizontalAlignment = UIControlContentVerticalAlignmentCenter;
        _titleBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleBtn.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
        [_titleBtn setImage:[UIImage imageNamedFromBundle:@"btn_album_more"] forState:UIControlStateNormal];
        _titleBtn.hidden = YES;
        [_titleBtn addTarget:self action:@selector(clickTitleViewAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _titleBtn;
}

- (CLAlbumTableView *)albumView{
    if (!_albumView) {
        _albumView = [[CLAlbumTableView alloc] init];
        cl_WS(ws);
        [_albumView setDidSelectAlbumBlock:^(CLAlbumModel *model) {
            if (![model.title isEqualToString:ws.albumModel.title]) {
                ws.albumModel = model;
                [ws _initData];
            }
        }];
        [_albumView setDisMissAlbumBlock:^{
            [UIView animateWithDuration:CLLittleControlAnimationTime animations:^{
                [ws.titleBtn.imageView setTransform:CGAffineTransformIdentity];
            } completion:^(BOOL finished) {
            }];
        }];
        [self.view addSubview:_albumView];
    }
    return _albumView;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            [_collectionView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAlways];
        }
        [_collectionView registerClass:[CLPhotoCollectionCell class] forCellWithReuseIdentifier:itemIdentifier];
        [_collectionView registerClass:[CLTakePhotoCell class] forCellWithReuseIdentifier:takeIdentifier];
        [self.view insertSubview:_collectionView atIndex:0];
        if (@available(iOS 9.0, *)) {
            if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable){
                [self registerForPreviewingWithDelegate:(id)self sourceView:_collectionView];
            }
        }
    }
    return _collectionView;
}

- (CLDoneButton *)doneBtn{
    if (!_doneBtn) {
        _doneBtn = [CLDoneButton buttonWithType:UIButtonTypeCustom];
        CGFloat doneWidth = GetMatchValue(CLString(@"CLText_Done"), CLNavigationItemFontSize, YES, CLToolBarHeight) + CLNavigationItemFontSize + 2;
        _doneBtn.frame = CGRectMake(0, 0, doneWidth, self.navigationController.navigationBar.height);
        _doneBtn.titleColor = self.picker.navigationItemColor;
        _doneBtn.numberColor = CLSeletedNumberColor;
        _doneBtn.titleFontSize = CLNavigationItemFontSize;
        cl_WS(ws);
        [_doneBtn setClickDoneBlock:^{
            [ws clickDoneItemAction];
        }];
        [self refreshBottomToolBarStatus];
    }
    return _doneBtn;
}

- (CLPickerToolBar *)toolBar{
    if (!_toolBar) {
        _toolBar = [[CLPickerToolBar alloc] init];
        _toolBar.titleColor = self.picker.toolBarItemColor?:self.picker.navigationItemColor;
        _toolBar.fontSize = CLToolBarTitleFontSize;
        _toolBar.backgroundColor = [(self.picker.toolBarBackgroundColor?:self.picker.navigationColor) colorWithAlphaComponent:CLToolBarAlpha];
        cl_WS(ws);
        if (self.picker.allowPreviewImage) {
            _toolBar.previewBtn.hidden = NO;
            [_toolBar setClickPreviewBlock:^{
                NSArray *array = [NSArray arrayWithArray:ws.picker.selectedModels];
                [ws gotoPreviewController:0 modelArray:array];
            }];
        }
        if (self.picker.allowEditImage) {
            _toolBar.editBtn.hidden = NO;
            [_toolBar setClickEditBlock:^{
                [ws clickEidtImageAction];
            }];
        }
        if (self.picker.allowSelectOriginalImage) {
            _toolBar.originalBtn.selected = self.picker.selectedOriginalImage;
            _toolBar.originalBtn.hidden = NO;
            [_toolBar setClickOriginalBlock:^(BOOL selected) {
                ws.picker.selectedOriginalImage = selected;
                [ws refreshBottomToolBarStatus];
            }];
        }
        if (self.picker.allowDoneOnToolBar) {
            _toolBar.doneBtn.hidden = NO;
            _toolBar.doneBtn.numberColor = CLSeletedNumberColor;
            [_toolBar.doneBtn setClickDoneBlock:^{
                [ws clickDoneItemAction];
            }];
        }
        [self refreshBottomToolBarStatus];
        [self.view addSubview:_toolBar];
    }
    return _toolBar;
}

#pragma mark -
#pragma mark -- 3D Touch UIViewControllerPreviewingDelegate --
- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
    if (!indexPath) {
        return nil;
    }
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if ([cell isKindOfClass:[CLTakePhotoCell class]]) {
        return nil;
    }
    //设置突出区域
    previewingContext.sourceRect = [self.collectionView cellForItemAtIndexPath:indexPath].frame;
    CLTouchViewController *vc = [[CLTouchViewController alloc] init];
    NSInteger index = indexPath.row;
    if (self.picker.allowTakePhoto && !self.picker.sortAscending) {
        index = indexPath.row - 1;
    }
    CLPhotoModel *model = self.photoArray[index];
    vc.index = index;
    vc.model = model;
    vc.preferredContentSize = [self getSize:model];
    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit{
    if ([viewControllerToCommit isKindOfClass:[CLTouchViewController class]]) {
        CLTouchViewController *vc = (CLTouchViewController *)viewControllerToCommit;
        if (vc.index < _photoArray.count) {
            cl_WS(ws);
            CLPreviewViewController *preview = [[CLPreviewViewController alloc] init];
            preview.currentIndex = vc.index;
            //        preview.currentModel = _photoArray[index];
            preview.photoArray = _photoArray;
            [preview setDidReloadToolBarStatus:^(BOOL reload){
                if (reload) {
                    [ws.collectionView reloadData];
                }
                [ws refreshBottomToolBarStatus];
            }];
            [self showViewController:preview sender:self];
        }
    }
}

- (CGSize)getSize:(CLPhotoModel *)model{
    CGFloat w = MIN(model.asset.pixelWidth, self.view.width);
    CGFloat h = w * model.asset.pixelHeight / model.asset.pixelWidth;
    if (isnan(h)) return CGSizeZero;
    if (h > self.view.height || isnan(h)) {
        h = self.view.height;
        w = h * model.asset.pixelWidth / model.asset.pixelHeight;
    }
    return CGSizeMake(w, h);
}

-(void)dealloc{
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
