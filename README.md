# CLPhotoLib

[![CI Status](https://img.shields.io/travis/claudeli@yeah.net/CLPhotoLib.svg?style=flat)](https://travis-ci.org/claudeli@yeah.net/CLPhotoLib)
[![Version](https://img.shields.io/cocoapods/v/CLPhotoLib.svg?style=flat)](https://cocoapods.org/pods/CLPhotoLib)
[![License](https://img.shields.io/cocoapods/l/CLPhotoLib.svg?style=flat)](https://cocoapods.org/pods/CLPhotoLib)
[![Platform](https://img.shields.io/cocoapods/p/CLPhotoLib.svg?style=flat)](https://cocoapods.org/pods/CLPhotoLib)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

```
a.视频、图片(包含GIF、LivePhoto、原图)的选择
b.3Dtouch预览
c.手势滑动选择
d.视频压缩，裁剪，水印及自定义颜色填充处理
e.图片处理（待处理）
f.支持多语言
g.适配iOS 11，iPhone X
```

## Installation

CLPhotoLib is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CLPhotoLib'


注意: plist添加
<key>CFBundleAllowMixedLocalizations</key>
<true/>
<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
<key>NSCameraUsageDescription</key>
<string>请允许访问摄像头</string>
<key>NSMicrophoneUsageDescription</key>
<string>请允许访问麦克风</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>请允许访问相册</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>请允许访问相册</string>
```

## Author

claudeli@yeah.net

## License

CLPhotoLib is available under the MIT license. See the LICENSE file for more info.
