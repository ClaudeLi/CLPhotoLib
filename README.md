# CLPhotoLib
================

    a.视频、图片(包含GIF、LivePhoto、原图)的选择
    b.3Dtouch预览
    c.手势滑动选择
    d.视频压缩，裁剪，水印及自定义颜色填充处理
    e.图片处理（待处理）
    f.支持多语言
    g.适配iOS 11，iPhone X
    
=================

    1.使用
        导入目录下的CLPhotoSDK文件夹（包含CLPhotoLib.framework和CLPhotoLib.bundle）
        或者引入CLPhotoLib.xcodeproj和CLPhotoLib.bundle
        也可以自己打包Framework

    2.plist添加
        <key>CFBundleAllowMixedLocalizations</key>
        <true/>
        <key>UIViewControllerBasedStatusBarAppearance</key>
        <false/>
        <key>NSCameraUsageDescription</key>
        <string>请允许访问你的摄像头</string>
        <key>NSMicrophoneUsageDescription</key>
        <string>请允许访问你的麦克风</string>
        <key>NSPhotoLibraryAddUsageDescription</key>
        <string>请允许访问你的相册</string>
        <key>NSPhotoLibraryUsageDescription</key>
        <string>请允许访问你的相册</string>

    3. CLPhotoLib中使用了category 在Other Linker Flags 添加 -ObjC、-all_load
    4.案例 跳跳App
