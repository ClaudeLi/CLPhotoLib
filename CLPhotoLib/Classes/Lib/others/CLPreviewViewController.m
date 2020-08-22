//
//  CLPreviewViewController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/7.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLPreviewViewController.h"
#import "CLPickerRootController.h"
#import "CLEditVideoController.h"
#import "CLEditImageController.h"
#import "CLPreviewCollectioCell.h"
#import "CLPickerToolBar.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

static CGFloat  minimumLineSpacing = 20.0f;
static NSString *itemIdentifier = @"CLPreviewCollectioCellItemIdentifier";
@interface CLPreviewViewController ()<UICollectionViewDelegate, UICollectionViewDataSource> {
    UICollectionViewFlowLayout *_layout;
    BOOL                        _hideBar;
    CLPhotoModel               *_currentModel;
}

@property (nonatomic, strong) UIButton         *rightItem;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CLPickerToolBar  *toolBar;
@property (nonatomic, assign) NSInteger         currentPage;

@end

@implementation CLPreviewViewController

- (CLPickerRootController *)picker {
    return (CLPickerRootController *)self.navigationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self _initNavigationItems];
    self.view.layer.masksToBounds = YES;
    self.collectionView.backgroundColor = [UIColor blackColor];
    self.currentPage = self.currentIndex;
    [self refreshNavigationBar];
    self.toolBar.hidden = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self play];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [UIApplication sharedApplication].statusBarHidden = _hideBar;
    self.navigationController.navigationBar.hidden = _hideBar;
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11, *)) {
        inset = self.view.safeAreaInsets;
    }
    _toolBar.frame = CGRectMake(0, self.view.height - CLToolBarHeight - inset.bottom, self.view.width, CLToolBarHeight + inset.bottom);
    _layout.itemSize = CGSizeMake(self.view.width, self.view.height);
    [_collectionView setCollectionViewLayout:_layout];
    _collectionView.frame = CGRectMake(-minimumLineSpacing/2.0, 0, minimumLineSpacing+self.view.width, self.view.height);
    [_collectionView setContentOffset:CGPointMake((self.view.width+minimumLineSpacing)*_currentIndex, 0)];
}

- (void)_initNavigationItems {
    UIButton *leftItem = [UIButton buttonWithType:UIButtonTypeCustom];
    leftItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    leftItem.frame = CGRectMake(0, 0, self.navigationController.navigationBar.height, self.navigationController.navigationBar.height);
    [leftItem setImage:[UIImage imageNamedFromBundle:@"btn_backItem_icon"] forState:UIControlStateNormal];
    [leftItem addTarget:self action:@selector(clickCancelItemAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:leftItem];
    if (self.picker.allowImgMultiple) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightItem];
    }
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)clickCancelItemAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)clickRightItemAction:(UIButton *)sender {
    if (_photoArray.count > _currentIndex) {
        CLPhotoModel *model = _photoArray[_currentIndex];
        if (!sender.selected) {
            // ToDo : 检测选择个数
            if (self.picker.selectedModels.count < self.picker.maxSelectCount) {
                model.isSelected = YES;
                if (![CLPhotoManager checkSelcectedWithModel:model identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:self.picker.selectedModels]]) {
                    [self.picker.selectedModels addObject:model];
                }
            } else {
                [self.picker showText:[NSString stringWithFormat:CLString(@"CLText_MaxImagesCount"), self.picker.maxSelectCount]];
                return;
            }
        } else {
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:self.picker.selectedModels];
            [selectedModels enumerateObjectsUsingBlock:^(CLPhotoModel  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([model.asset.localIdentifier isEqualToString:obj.asset.localIdentifier]) {
                    [self.picker.selectedModels removeObject:obj];
                }
            }];
        }
    }
    [self refreshBottomToolBarReloadList:YES];
    sender.selected = !sender.selected;
    if (sender.selected) {
        [UIView showOscillatoryAnimationWithLayer:sender.layer type:CLOscillatoryAnimationToBigger];
    }
}

- (void)clickDoneItemAction {
    if (_currentPage < _photoArray.count) {
        CLPreviewCollectioCell *cell = (CLPreviewCollectioCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_currentPage inSection:0]];
        if (cell) {
            [cell pausePlay:YES];
        }
    }
    if (_currentModel.type == CLAssetMediaTypeVideo) {
        [self.picker showProgress];
        cl_weakSelf(self);
        [CLPhotoShareManager requestVideoAssetForAsset:_currentModel.asset completion:^(AVAsset *asset, NSDictionary *info) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            if (!asset) {
                [strongSelf.picker showText:CLString(@"CLText_NotGetVideoInfo")];
                return;
            }
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if([tracks count] > 0) {
                if ([[tracks firstObject] isKindOfClass:[AVCompositionTrack class]]) {
                    [strongSelf.picker showText:CLString(@"CLText_UnableToDecode")];
                } else {
                    [strongSelf.picker clickPickingVideoActionForAsset:asset
                                                                 range:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                                               degrees:0];
                }
            } else {
                [strongSelf.picker showText:CLString(@"CLText_NotGetVideoInfo")];
            }
        }];
    } else {
        if (self.picker.allowImgMultiple) {
            [self.picker didFinishPickingPhotosAction];
        } else {
            if (_photoArray.count > _currentIndex) {
                CLPhotoModel *model = _photoArray[_currentIndex];
                if (![CLPhotoManager checkSelcectedWithModel:model identifiers:[CLPhotoManager getLocalIdentifierArrayWithArray:self.picker.selectedModels]]) {
                    [self.picker.selectedModels addObject:model];
                    [self.picker didFinishPickingPhotosAction];
                }
            }
        }
    }
}

- (void)clickEditAction {
    if (_currentPage < _photoArray.count) {
        CLPreviewCollectioCell *cell = (CLPreviewCollectioCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_currentPage inSection:0]];
        if (cell) {
            [cell pausePlay:YES];
        }
    }
    if (_currentModel.type == CLAssetMediaTypeVideo) {
        CLEditVideoController *edit = [[CLEditVideoController alloc] init];
        edit.model = _currentModel;
        [self.navigationController pushViewController:edit animated:NO];
    } else {
        CLEditImageController *image = [[CLEditImageController alloc] init];
        image.model = _currentModel;
        [self.navigationController pushViewController:image animated:NO];
    }
}

#pragma mark -
#pragma mark -- UICollectionViewDataSource & UICollectionViewDelegate --
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CLPreviewCollectioCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemIdentifier forIndexPath:indexPath];
    cell.showGif = self.picker.allowSelectGif;
    cell.showLivePhoto = self.picker.allowSelectLivePhoto;
    if (_photoArray.count > indexPath.row) {
        cell.model = _photoArray[indexPath.row];
    }
    cl_weakSelf(self);
    cell.singleTapCallBack = ^() {
        cl_strongSelf(weakSelf);
        [strongSelf handlerSingleTap];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(CLPreviewCollectioCell *)cell resetScale];
    ((CLPreviewCollectioCell *)cell).willDisplaying = YES;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(CLPreviewCollectioCell *)cell pausePlay:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//    return CGSizeMake(self.view.width, self.view.height);
//}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, minimumLineSpacing/2.0, 0, minimumLineSpacing/2.0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == (UIScrollView *)_collectionView) {
        CGPoint offSet = scrollView.contentOffset;
        _currentPage = (offSet.x + ((minimumLineSpacing + self.view.width) * 0.5)) / (minimumLineSpacing + self.view.width);
        [self refreshNavigationBar];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat page = scrollView.contentOffset.x/(minimumLineSpacing + self.view.width);
    if (ceilf(page) >= _photoArray.count) {
        return;
    }
    _currentIndex = [[NSString stringWithFormat:@"%.0f", page] integerValue];
    [self play];
}

#pragma mark -
#pragma mark -- Private Methods --
- (void)play {
    if (_photoArray.count > _currentIndex) {
        CLPhotoModel *model = _photoArray[_currentIndex];
        if (model.type == CLAssetMediaTypeGif ||
            model.type == CLAssetMediaTypeLivePhoto) {
            if ([_collectionView numberOfItemsInSection:0] > _currentIndex) {
                CLPreviewCollectioCell *cell = (CLPreviewCollectioCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentIndex inSection:0]];
                cell.willDisplaying = YES;
                [cell reloadGif];
            }
        }
    }
}

- (void)handlerSingleTap {
    _hideBar = !_hideBar;
    [UIApplication sharedApplication].statusBarHidden = _hideBar;
    self.navigationController.navigationBar.hidden = _hideBar;
    _toolBar.hidden = _hideBar;
}

- (void)refreshNavigationBar {
    if (_photoArray.count > _currentPage) {
        CLPhotoModel *model = _photoArray[_currentPage];
        if ([model.asset.localIdentifier isEqualToString:_currentModel.asset.localIdentifier]) {
            return;
        }
        _currentModel = model;
        self.rightItem.selected = model.isSelected;
        //改变导航标题
        self.title = [NSString stringWithFormat:@"%ld/%ld", (long)(_currentPage + 1), (long)_photoArray.count];
        [self switchToVideo];
    }
}

- (BOOL)switchToVideo {
    if (_currentModel.type == CLAssetMediaTypeVideo) {
        if (self.picker.allowSelectOriginalImage) {
            _toolBar.originalBtn.hidden = YES;
        }
        self.rightItem.hidden = YES;
        _toolBar.doneBtn.number = 0;

        _toolBar.tipLabel.hidden = NO;
        if (self.picker.minDuration > _currentModel.duration) {
            [_toolBar.tipLabel setTitle:[NSString stringWithFormat:CLString(@"CLText_VideoLengthLeast"), @(self.picker.minDuration)] forState:UIControlStateNormal];
            _toolBar.tipLabel.hidden = NO;
            _toolBar.doneBtn.selected = NO;
            _toolBar.editSelect = NO;
        } else if (self.picker.maxDuration < _currentModel.duration) {
            [_toolBar.tipLabel setTitle:[NSString stringWithFormat:CLString(@"CLText_VideoMaximumLength"), @(self.picker.maxDuration)] forState:UIControlStateNormal];
            _toolBar.tipLabel.hidden = NO;
            _toolBar.doneBtn.selected = NO;
            _toolBar.editSelect = YES;
        } else {
            _toolBar.doneBtn.selected = YES;
            _toolBar.tipLabel.hidden = YES;
            _toolBar.editSelect = YES;
        }
        return YES;
    }
    if (self.rightItem.hidden) {
        self.rightItem.hidden = NO;
    }
    if (_toolBar) {
        _toolBar.tipLabel.hidden = YES;
        if (self.picker.allowSelectOriginalImage) {
            if (_toolBar.originalBtn.hidden) {
                _toolBar.originalBtn.hidden = NO;
            }
        }
        if (self.picker.selectedModels.count == 0) {
            if (self.picker.allowImgMultiple) {
                _toolBar.doneBtn.selected = NO;
            } else {
                _toolBar.doneBtn.selected = YES;
            }
        }
        if (_toolBar.doneBtn.number != self.picker.selectedModels.count) {
            _toolBar.doneBtn.number = self.picker.selectedModels.count;
        }
        _toolBar.editSelect = self.picker.allowEditImage;
    }
    return NO;
}

- (void)refreshBottomToolBarReloadList:(BOOL)reload {
    [self refreshBottomToolBarStatus];
    if (self.didReloadToolBarStatus) {
        self.didReloadToolBarStatus(reload);
    }
}

- (void)refreshBottomToolBarStatus {
    if ([self switchToVideo]) return;
    if (self.picker.allowSelectOriginalImage) {
        _toolBar.originalBtn.hidden = NO;
        _toolBar.originalBtn.selected = self.picker.selectedOriginalImage;
        if (self.picker.selectedModels.count) {
            if (_toolBar.originalBtn.selected) {
                [self getOriginalImageBytes];
            } else {
                [_toolBar.originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
            }
        } else {
            [_toolBar.originalBtn setTitle:CLString(@"CLText_Original") forState:UIControlStateNormal];
        }
    }
    if (_toolBar.doneBtn.number != self.picker.selectedModels.count) {
        _toolBar.doneBtn.number = self.picker.selectedModels.count;
    }
}

- (void)getOriginalImageBytes {
    [_toolBar startAnimating];
    CLPickerRootController *pk = self.picker;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        cl_weakSelf(self);
        [CLPhotoManager getPhotosBytesWithArray:pk.selectedModels completion:^(NSString *photosBytes) {
            cl_strongSelf(weakSelf);
            if (!strongSelf) {
                return;
            }
            [strongSelf performSelector:@selector(setOriginalImageBytes:) withObject:photosBytes afterDelay:0.2];
        }];
    });
}

- (void)setOriginalImageBytes:(id)object {
    cl_weakSelf(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.toolBar stopAnimating];
        [weakSelf.toolBar.originalBtn setTitle:[NSString stringWithFormat:@"%@(%@)", CLString(@"CLText_Original"), object] forState:UIControlStateNormal];
    });
}

#pragma mark -
#pragma mark -- Lazy Loads --
- (UIButton *)rightItem {
    if (!_rightItem) {
        _rightItem = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightItem.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _rightItem.frame = CGRectMake(0, 0, self.navigationController.navigationBar.height, self.navigationController.navigationBar.height);
        [_rightItem setImage:[UIImage imageNamedFromBundle:@"btn_photo_unselected"] forState:UIControlStateNormal];
        [_rightItem setImage:[UIImage imageNamedFromBundle:@"btn_photo_unselected"] forState:UIControlStateHighlighted];
        [_rightItem setImage:[UIImage imageNamedFromBundle:@"btn_photo_selected"] forState:UIControlStateSelected];
        [_rightItem setImage:[UIImage imageNamedFromBundle:@"btn_photo_selected"] forState:UIControlStateSelected|UIControlStateHighlighted];
        [_rightItem addTarget:self action:@selector(clickRightItemAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rightItem;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:_layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.scrollsToTop = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_collectionView registerClass:[CLPreviewCollectioCell class] forCellWithReuseIdentifier:itemIdentifier];
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}

- (CLPickerToolBar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[CLPickerToolBar alloc] init];
        _toolBar.titleColor = self.picker.toolBarItemColor?:self.picker.navigationItemColor;
        _toolBar.fontSize = CLToolBarTitleFontSize;
        _toolBar.backgroundColor = [(self.picker.toolBarBackgroundColor?:self.picker.navigationColor) colorWithAlphaComponent:CLToolBarAlpha];
        cl_WS(ws);
        if (!(!self.picker.allowEditImage && self.picker.selectMode == CLPickerSelectModeAllowImage)) {
            _toolBar.editBtn.hidden = NO;
            [_toolBar setClickEditBlock:^{
                [ws clickEditAction];
            }];
        }
        if (self.picker.allowSelectOriginalImage) {
            _toolBar.originalBtn.selected = self.picker.selectedOriginalImage;
            _toolBar.originalBtn.hidden = NO;
            [_toolBar setClickOriginalBlock:^(BOOL selected) {
                ws.picker.selectedOriginalImage = selected;
                [ws refreshBottomToolBarReloadList:NO];
            }];
        }
        _toolBar.tipLabel.hidden = YES;
        _toolBar.doneBtn.hidden = NO;
        _toolBar.doneBtn.numberColor = CLSeletedNumberColor;
        [_toolBar.doneBtn setClickDoneBlock:^{
            [ws clickDoneItemAction];
        }];
        [self refreshBottomToolBarStatus];
        [self.view addSubview:_toolBar];
    }
    return _toolBar;
}

- (void)dealloc {
    [self.picker cancelExport];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
