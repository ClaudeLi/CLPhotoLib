//
//  CLAssetModel.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/6/29.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "CLAssetModel.h"
#import "CLImageManager.h"

@implementation CLAssetModel

+ (instancetype)modelWithAsset:(id)asset type:(CLAssetModelMediaType)type{
    CLAssetModel *model = [[CLAssetModel alloc] init];
    model.asset = asset;
    model.isSelected = NO;
    model.type = type;
    return model;
}

+ (instancetype)modelWithAsset:(id)asset type:(CLAssetModelMediaType)type timeLength:(NSString *)timeLength {
    CLAssetModel *model = [self modelWithAsset:asset type:type];
    model.timeLength = timeLength;
    return model;
}

@end



@implementation CLAlbumModel

- (void)setResult:(id)result {
    _result = result;
    BOOL allowPickingImage = [[[NSUserDefaults standardUserDefaults] objectForKey:@"cl_allowPickingImage"] isEqualToString:@"1"];
    BOOL allowPickingVideo = [[[NSUserDefaults standardUserDefaults] objectForKey:@"cl_allowPickingVideo"] isEqualToString:@"1"];
    [[CLImageManager manager] getAssetsFromFetchResult:result allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage completion:^(NSArray<CLAssetModel *> *models) {
        _models = models;
        if (_selectedModels) {
            [self checkSelectedModels];
        }
    }];
}

- (void)setSelectedModels:(NSArray *)selectedModels {
    _selectedModels = selectedModels;
    if (_models) {
        [self checkSelectedModels];
    }
}

- (void)checkSelectedModels {
    self.selectedCount = 0;
    NSMutableArray *selectedAssets = [NSMutableArray array];
    for (CLAssetModel *model in _selectedModels) {
        [selectedAssets addObject:model.asset];
    }
    for (CLAssetModel *model in _models) {
        if ([[CLImageManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
            self.selectedCount ++;
        }
    }
}

@end
