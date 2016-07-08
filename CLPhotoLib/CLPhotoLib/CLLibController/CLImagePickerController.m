//
//  CLImagePickerController.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "CLImagePickerController.h"
#import "CLPhotoLib.h"
#import "CLPhotoPreviewController.h"
#import "CLAssetCell.h"
#import "CLAssetModel.h"
#import "CLVideoPlayerController.h"
#import "CLAlbumTableView.h"

@interface CLImagePickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIAlertViewDelegate> {
    CLPickerRootController *imagePicker;
    UIButton* titleBtn;
    CLAlbumTableView *albumView;
    NSMutableArray *_models;
    UIButton *_previewButton;
    UIButton *_okButton;
    UIImageView *_numberImageView;
    UILabel *_numberLable;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLable;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIImagePickerController *imageCamera;
@end

static CGSize AssetGridThumbnailSize;

@implementation CLImagePickerController

// 相机
- (UIImagePickerController *)imageCamera {
    if (_imageCamera == nil) {
        _imageCamera = [[UIImagePickerController alloc] init];
        _imageCamera.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imageCamera.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imageCamera.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *clBarItem, *BarItem;
        if (iOS9Later) {
            clBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[CLPickerRootController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            clBarItem = [UIBarButtonItem appearanceWhenContainedIn:[CLPickerRootController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [clBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imageCamera;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = CLBgViewColor;
    imagePicker = (CLPickerRootController *)self.navigationController;
    _isSelectOriginalPhoto = imagePicker.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;

    if (imagePicker.canGoBackAlbum) {
        self.navigationItem.title = _model.name;
    }else{
        titleBtn = [UIButton new];
        titleBtn.frame = CGRectMake(0, 0, self.view.cl_width - 150, 25);
        [titleBtn setImage:[UIImage imageNamedFromCLBundle:@"more_album.png"] forState:UIControlStateNormal];
        [titleBtn setTitle:_model.name forState:UIControlStateNormal];
        [titleBtn addTarget:self action:@selector(setAlbumList:) forControlEvents:UIControlEventTouchUpInside];
        [self updateTitBtnLayout];
        self.navigationItem.titleView = titleBtn;
        [self setNavigationItem];
        albumView = [[CLAlbumTableView alloc] initWithFrame:CGRectMake(0,  CLNavigationHeight, CLScreenWidth, CLScreenHeight - CLNavigationHeight)];
        __weak typeof(titleBtn) weakBtn = titleBtn;
        CL_WS(ws);
        [albumView setSelectAlbumBlock:^(CLAlbumModel *model) {
            if (![model.name isEqualToString:ws.model.name]) {
                _model = model;
                [weakBtn setTitle:model.name forState:UIControlStateNormal];
                [ws updateTitBtnLayout];
                [ws updatePhotosWith:model];
            }
        }];
        [albumView setDisMissBlock:^{
            [UIView animateWithDuration:0.2 animations:^{
                [weakBtn.imageView setTransform:CGAffineTransformIdentity];
            } completion:^(BOOL finished) {
            }];
        }];
    }
    [self setUpPhotos];
}

- (void)updateTitBtnLayout{
    CGFloat imageWith = titleBtn.imageView.frame.size.width;
    CGFloat labelWidth = titleBtn.titleLabel.frame.size.width;
    titleBtn.imageEdgeInsets = UIEdgeInsetsMake(0, labelWidth, 0, -labelWidth);
    titleBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -imageWith, 0, imageWith);
}

- (void)setAlbumList:(UIButton *)sender{
    if (!sender.selected) {
        [[CLImageManager manager] getAllAlbums:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(NSArray<CLAlbumModel *> *models) {
            albumView.albumArray = [NSMutableArray arrayWithArray:models];
            for (CLAlbumModel *albumModel in albumView.albumArray) {
                albumModel.selectedModels = imagePicker.selectedModels;
            }
            [albumView showInView:self.view];
            [UIView animateWithDuration:0.2 animations:^{
                CGAffineTransform transform = titleBtn.imageView.transform;
                CGAffineTransform transform2 =  CGAffineTransformRotate(transform, M_PI);
                [titleBtn.imageView setTransform:transform2];
            } completion:^(BOOL finished) {
            }];
        }];
    }else{
        [albumView dismiss];
    }
    sender.selected = !sender.selected;
}

- (void)updatePhotosWith:(CLAlbumModel *)albumModel{
    [[CLImageManager manager] getAssetsFromFetchResult:albumModel.result allowPickingVideo:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(NSArray<CLAssetModel *> *models) {
        _models = [NSMutableArray arrayWithArray:models];
        [self checkSelectedModels];
        [self.collectionView reloadData];
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }];
}

- (void)setUpPhotos{
    _showTakePhotoBtn = (([_model.name isEqualToString:@"相机胶卷"] || [_model.name isEqualToString:@"Camera Roll"] ||  [_model.name isEqualToString:@"所有照片"] || [_model.name isEqualToString:@"All Photos"]) && imagePicker.allowTakePicture);
    if (!imagePicker.sortAscendingByModificationDate && _isFirstAppear && iOS8Later) {
        [[CLImageManager manager] getCameraRollAlbum:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(CLAlbumModel *model) {
            _model = model;
            _models = [NSMutableArray arrayWithArray:_model.models];
            [self initSubviews];
        }];
    } else {
        if (_showTakePhotoBtn || !iOS8Later || _isFirstAppear) {
            [[CLImageManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(NSArray<CLAssetModel *> *models) {
                _models = [NSMutableArray arrayWithArray:models];
                [self initSubviews];
            }];
        } else {
            _models = [NSMutableArray arrayWithArray:_model.models];
            [self initSubviews];
        }
    }
}

- (void)initSubviews {
    [self checkSelectedModels];
    [self configCollectionView];
    if (imagePicker.allowShowToolBar) {
        [self configBottomToolBar];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    imagePicker.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    if (self.backButtonClickHandle) {
        self.backButtonClickHandle(_model);
    }
}

- (void)configCollectionView {
    CGFloat _count = imagePicker.listCount;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat itemWH = self.view.cl_width/_count;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
//    layout.sectionInset = UIEdgeInsetsMake(0, 0.2, 0, 0.2);
    CGFloat h = self.view.cl_height;
    if (imagePicker.allowShowToolBar) {
        h = self.view.cl_height - CLToolBarHeight;
    }
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.cl_width, h) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.backgroundColor = CLBgViewColor;

    if (imagePicker.allowTakePicture) {
        _collectionView.contentSize = CGSizeMake(self.view.cl_width, ((_model.count + 4) / 4) * self.view.cl_width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.cl_width, ((_model.count + 3) / 4) * self.view.cl_width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[CLAssetCell class] forCellWithReuseIdentifier:@"CLAssetCell"];
    [_collectionView registerClass:[CLAssetCameraCell class] forCellWithReuseIdentifier:@"CLAssetCameraCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollCollectionViewToBottom];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if (CLScreenWidth > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

- (void)setNavigationItem{
    UIButton* leftItem = [UIButton new];
    leftItem.frame = CGRectMake(0, 0, 40, CLTitleHeight);
    [leftItem setTitle:@"取消" forState:UIControlStateNormal];
    leftItem.titleLabel.textAlignment = NSTextAlignmentLeft;
    [leftItem addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, CLTitleHeight)];
    [leftView addSubview:leftItem];
    [leftView addSubview:[[UIView alloc] initWithFrame:CGRectMake(0, 40, 30, CLTitleHeight)]];
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftBarButtonItem = left;
    
    _okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _okButton.frame = CGRectMake(30, 0, 40, CLTitleHeight);
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:@"确定" forState:UIControlStateNormal];
    [_okButton setTitle:@"确定" forState:UIControlStateDisabled];
    [_okButton setTitleColor:CLNumBGViewNormalColor forState:UIControlStateNormal];
    [_okButton setTitleColor:CLNumBGViewDisabledColor forState:UIControlStateDisabled];
    _okButton.enabled = imagePicker.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromCLBundle:@"photo_number_icon.png"]];
    _numberImageView.frame = CGRectMake(4, 9, 26, 26);
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLable = [[UILabel alloc] init];
    _numberLable.frame = _numberImageView.bounds;
    _numberLable.font = [UIFont systemFontOfSize:16];
    _numberLable.textColor = [UIColor whiteColor];
    _numberLable.textAlignment = NSTextAlignmentCenter;
    _numberLable.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    _numberLable.hidden = imagePicker.selectedModels.count <= 0;
    _numberLable.backgroundColor = [UIColor clearColor];
    [_numberImageView addSubview:_numberLable];
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70,CLTitleHeight)];
    [rightView addSubview:_numberImageView];
    [rightView addSubview:_okButton];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithCustomView:rightView];
    self.navigationItem.rightBarButtonItem = right;
}


- (void)configBottomToolBar {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.cl_height - CLToolBarHeight, self.view.cl_width, CLToolBarHeight)];
    bottomToolBar.backgroundColor = CLToolBarColor;
    
    _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _previewButton.frame = CGRectMake(10, 3, 44, 44);
    [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_previewButton setTitle:@"预览" forState:UIControlStateNormal];
    [_previewButton setTitle:@"预览" forState:UIControlStateDisabled];
    [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _previewButton.enabled = imagePicker.selectedModels.count;
    
    if (imagePicker.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.frame = CGRectMake(50, self.view.cl_height - CLToolBarHeight, 130, CLToolBarHeight);
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0);
        _originalPhotoButton.contentEdgeInsets = UIEdgeInsetsMake(0, -45, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:[UIImage imageNamedFromCLBundle:@"photo_original_def.png"] forState:UIControlStateNormal];
        [_originalPhotoButton setImage:[UIImage imageNamedFromCLBundle:@"photo_original_sel.png"] forState:UIControlStateSelected];
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = imagePicker.selectedModels.count > 0;
        
        _originalPhotoLable = [[UILabel alloc] init];
        _originalPhotoLable.frame = CGRectMake(70, 0, 60, CLToolBarHeight);
        _originalPhotoLable.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLable.font = [UIFont systemFontOfSize:16];
        _originalPhotoLable.textColor = [UIColor blackColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _okButton.frame = CGRectMake(self.view.cl_width - 44 - 12, 3, 44, 44);
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:@"确定" forState:UIControlStateNormal];
    [_okButton setTitle:@"确定" forState:UIControlStateDisabled];
    [_okButton setTitleColor:CLNumBGViewNormalColor forState:UIControlStateNormal];
    [_okButton setTitleColor:CLNumBGViewDisabledColor forState:UIControlStateDisabled];
    _okButton.enabled = imagePicker.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromCLBundle:@"photo_number_icon.png"]];
    _numberImageView.frame = CGRectMake(self.view.cl_width - 56 - 24, 12, 26, 26);
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLable = [[UILabel alloc] init];
    _numberLable.frame = _numberImageView.frame;
    _numberLable.font = [UIFont systemFontOfSize:16];
    _numberLable.textColor = [UIColor whiteColor];
    _numberLable.textAlignment = NSTextAlignmentCenter;
    _numberLable.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    _numberLable.hidden = imagePicker.selectedModels.count <= 0;
    _numberLable.backgroundColor = [UIColor clearColor];
    
    UIView *divide = [[UIView alloc] init];
    divide.backgroundColor = CL_RGBA(222, 222, 222, 1);
    divide.frame = CGRectMake(0, 0, self.view.cl_width, 0.5);
    
    [bottomToolBar addSubview:divide];
    [bottomToolBar addSubview:_previewButton];
    [bottomToolBar addSubview:_okButton];
    [bottomToolBar addSubview:_numberImageView];
    [bottomToolBar addSubview:_numberLable];
    [self.view addSubview:bottomToolBar];
    [self.view addSubview:_originalPhotoButton];
    [_originalPhotoButton addSubview:_originalPhotoLable];
}

#pragma mark - Click Event

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [imagePicker.pickerDelegate imagePickerControllerDidCancel:imagePicker];
    }
    if (imagePicker.imagePickerControllerDidCancelHandle) {
        imagePicker.imagePickerControllerDidCancelHandle();
    }
}

- (void)previewButtonClick {
    CLPhotoPreviewController *photoPreviewVc = [[CLPhotoPreviewController alloc] init];
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLable.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)okButtonClick {
    [imagePicker showProgressHUD];
    [CLImageManager manager].shouldFixOrientation = YES;
    if (imagePicker.allowPickingImage) {
        NSMutableArray *photos = [NSMutableArray array];
        NSMutableArray *assets = [NSMutableArray array];
        NSMutableArray *infoArr = [NSMutableArray array];
        for (NSInteger i = 0; i < imagePicker.selectedModels.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; }
        for (NSInteger i = 0; i < imagePicker.selectedModels.count; i++) {
            CLAssetModel *model = imagePicker.selectedModels[i];
            [[CLImageManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if (isDegraded) return;
                if (photo) {
                    photo = [UIImage scaleImage:photo toSize:imagePicker.minSideSize];
                    [photos replaceObjectAtIndex:i withObject:photo];
                }
                if (info)  [infoArr replaceObjectAtIndex:i withObject:info];
                [assets replaceObjectAtIndex:i withObject:model.asset];
                
                for (id item in photos) { if ([item isKindOfClass:[NSNumber class]]) return; }
                [imagePicker hideProgressHUD];
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
                        [imagePicker.pickerDelegate imagePickerController:imagePicker didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
                    }
                    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
                        [imagePicker.pickerDelegate imagePickerController:imagePicker didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
                    }
                    if (imagePicker.didFinishPickingPhotosHandle) {
                        imagePicker.didFinishPickingPhotosHandle(photos,assets,_isSelectOriginalPhoto);
                    }
                    if (imagePicker.didFinishPickingPhotosWithInfosHandle) {
                        imagePicker.didFinishPickingPhotosWithInfosHandle(photos,assets,_isSelectOriginalPhoto,infoArr);
                    }
                }];
            }];
        }
    }else{
        CLAssetModel *model = imagePicker.selectedModels[0];
        [[CLImageManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            [imagePicker hideProgressHUD];
            if (photo) {
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    if ([imagePicker.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
                        [imagePicker.pickerDelegate imagePickerController:imagePicker didFinishPickingVideo:photo sourceAssets:model.asset];
                    }
                    if (imagePicker.didFinishPickingVideoHandle) {
                        imagePicker.didFinishPickingVideoHandle(photo,model.asset);
                    }
                }];
            }else{
                NSLog(@"视频封面读取失败");
            }
        }];
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (imagePicker.allowTakePicture) {
        return _models.count + 1;
    }
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    if (((imagePicker.sortAscendingByModificationDate && indexPath.row >= _models.count) || (!imagePicker.sortAscendingByModificationDate && indexPath.row == 0)) && imagePicker.allowTakePicture) {
        CLAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CLAssetCameraCell" forIndexPath:indexPath];
        if (imagePicker.allowPickingImage) {
            cell.imageView.image = [UIImage imageNamedFromCLBundle:@"takePicture.png"];
        }else{
            cell.imageView.image = [UIImage imageNamedFromCLBundle:@"VideoTakePicture.png"];
        }
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    CLAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CLAssetCell" forIndexPath:indexPath];
    CLAssetModel *model;
    if (imagePicker.sortAscendingByModificationDate || !imagePicker.allowTakePicture) {
        model = _models[indexPath.row];
    } else {
        model = _models[indexPath.row - 1];
    }
    cell.model = model;
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        // 1. cancel select / 取消选择
        if (isSelected) {
            weakCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:imagePicker.selectedModels];
            for (CLAssetModel *model_item in selectedModels) {
                if ([[[CLImageManager manager] getAssetIdentifier:model.asset] isEqualToString:[[CLImageManager manager] getAssetIdentifier:model_item.asset]]) {
                    [imagePicker.selectedModels removeObject:model_item];
                }
            }
            [weakSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePicker.selectedModels.count < imagePicker.maxImagesCount) {
                weakCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [imagePicker.selectedModels addObject:model];
                [weakSelf refreshBottomToolBarStatus];
            } else {
                [imagePicker showAlertWithTitle:[NSString stringWithFormat:@"你最多只能选择%zd张照片",imagePicker.maxImagesCount]];
            }
        }
        [UIView showOscillatoryAnimationWithLayer:weakLayer type:CLOscillatoryAnimationToSmaller];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    if (((imagePicker.sortAscendingByModificationDate && indexPath.row >= _models.count) || (!imagePicker.sortAscendingByModificationDate && indexPath.row == 0)) && imagePicker.allowTakePicture)  {
        if (imagePicker.allowPickingImage) {
            [self takePhoto]; return;
        }else{
            NSLog(@"去录制");
            return;
        }
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.row;
    if (!imagePicker.sortAscendingByModificationDate && imagePicker.allowTakePicture) {
        index = indexPath.row - 1;
    }
    CLAssetModel *model = _models[index];
    if (model.type == CLAssetModelMediaTypeVideo) {
//        [imagePicker showAlertWithTitle:@"选择照片时不能选择视频"];
        CLVideoPlayerController *videoPlayerVc = [[CLVideoPlayerController alloc] init];
        videoPlayerVc.model = model;
        [self.navigationController pushViewController:videoPlayerVc animated:YES];
    } else {
        CLPhotoPreviewController *photoPreviewVc = [[CLPhotoPreviewController alloc] init];
        photoPreviewVc.currentIndex = index;
        photoPreviewVc.models = _models;
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

#pragma mark - Private Method

- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) && iOS8Later) {
        // 无权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"去设置", nil];
        [alert show];
    } else { // 调用相机
        UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            self.imageCamera.sourceType = sourceType;
            if(iOS8Later) {
                _imageCamera.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            }
            [self presentViewController:_imageCamera animated:YES completion:nil];
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

- (void)refreshBottomToolBarStatus {
    _previewButton.enabled = imagePicker.selectedModels.count > 0;
    _okButton.enabled = imagePicker.selectedModels.count > 0;
    
    _numberImageView.hidden = imagePicker.selectedModels.count <= 0;
    _numberLable.hidden = imagePicker.selectedModels.count <= 0;
    _numberLable.text = [NSString stringWithFormat:@"%zd",imagePicker.selectedModels.count];
    
    _originalPhotoButton.enabled = imagePicker.selectedModels.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLable.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(CLPhotoPreviewController *)photoPreviewVc {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    photoPreviewVc.backButtonClickBlock = ^(BOOL isSelectOriginalPhoto) {
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    };
    photoPreviewVc.okButtonClickBlock = ^(BOOL isSelectOriginalPhoto){
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf okButtonClick];
    };
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    [[CLImageManager manager] getPhotosBytesWithArray:imagePicker.selectedModels completion:^(NSString *totalBytes) {
        _originalPhotoLable.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (void)scrollCollectionViewToBottom {
    if (_shouldScrollToBottom && _models.count > 0 && imagePicker.sortAscendingByModificationDate) {
        NSInteger item = _models.count - 1;
        if (imagePicker.allowPickingImage && imagePicker.allowTakePicture) {
            item += 1;
        }
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        _shouldScrollToBottom = NO;
    }
}

- (void)checkSelectedModels {
    for (CLAssetModel *model in _models) {
        model.isSelected = NO;
        NSMutableArray *selectedAssets = [NSMutableArray array];
        for (CLAssetModel *model in imagePicker.selectedModels) {
            [selectedAssets addObject:model.asset];
        }
        if ([[CLImageManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
            model.isSelected = YES;
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
        if (iOS8Later) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        } else {
            // [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy&path=Photos"]];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        [imagePicker showProgressHUD];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [[CLImageManager manager] savePhotoWithImage:image completion:^{
            [self reloadPhotoArray];
        }];
    }
}

- (void)reloadPhotoArray {
    [[CLImageManager manager] getCameraRollAlbum:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(CLAlbumModel *model) {
        _model = model;
        [[CLImageManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePicker.allowPickingVideo allowPickingImage:imagePicker.allowPickingImage completion:^(NSArray<CLAssetModel *> *models) {
            [imagePicker hideProgressHUD];
            
            CLAssetModel *assetModel;
            if (imagePicker.sortAscendingByModificationDate) {
                assetModel = [models lastObject];
                [_models addObject:assetModel];
            } else {
                assetModel = [models firstObject];
                [_models insertObject:assetModel atIndex:0];
            }
            if (imagePicker.selectedModels.count < imagePicker.maxImagesCount) {
                assetModel.isSelected = YES;
                [imagePicker.selectedModels addObject:assetModel];
                [self refreshBottomToolBarStatus];
            }
            [_collectionView reloadData];
            
            _shouldScrollToBottom = YES;
            [self scrollCollectionViewToBottom];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [[CLImageManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[CLImageManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                                                       targetSize:AssetGridThumbnailSize
                                                                      contentMode:PHImageContentModeAspectFill
                                                                          options:nil];
        [[CLImageManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                                                      targetSize:AssetGridThumbnailSize
                                                                     contentMode:PHImageContentModeAspectFill
                                                                         options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < _models.count) {
            CLAssetModel *model = _models[indexPath.item];
            [assets addObject:model.asset];
        }
    }
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end
