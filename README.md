# CLPhotoLib
图片选择器&lt;可选原图>、支持视频选择

// 使用方法

导入工程中的CLPhotoLib文件夹

引头 #import "CLPhotoLib.h"

遵循协议 CLPickerRootControllerDelegate

// 1.基本使用方法  <其他属性设置可查看 CLPickerRootController.h>

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

//2. 协议回调，也可以Block回调  
        - (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
            NSLog(@"%@", photos);
            _assets = [assets mutableCopy];
        }

// 如果用户选择了一个视频，下面的handle会被执行
// 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象
        - (void)imagePickerController:(CLPickerRootController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
            NSLog(@"%@", asset);
        }