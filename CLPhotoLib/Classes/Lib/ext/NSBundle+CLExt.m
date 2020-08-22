//
//  NSBundle+CLExt.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "NSBundle+CLExt.h"
#import "CLPhotoManager.h"

@implementation NSBundle (CLExt)

NSString *CLString(NSString *key) {
    return [NSBundle clLocalizedStringForKey:key];
};

+ (instancetype)clLocalizedBundle {
    static NSBundle *localBundle = nil;
    if (localBundle == nil) {
        localBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[CLPhotoManager class]] pathForResource:@"CLPhotoLib" ofType:@"bundle"]];
    }
    return localBundle;
}

+ (NSString *)clLocalizedStringForKey:(NSString *)key {
    return [self clLocalizedStringForKey:key value:nil];
}

+ (NSString *)clLocalizedStringForKey:(NSString *)key value:(NSString *)value {
    static NSBundle *bundle = nil;
    if (bundle == nil) {
        NSString *language = [NSLocale preferredLanguages].firstObject;
        if ([language hasPrefix:@"en"]) {
            language = @"en";
        } else if ([language hasPrefix:@"zh"]) {
            if ([language rangeOfString:@"Hans"].location != NSNotFound) {
                language = @"zh-Hans"; // 简体中文
            } else { // zh-Hant\zh-HK\zh-TW
                language = @"zh-Hant"; // 繁體中文
            }
        } else {
            language = @"en";
        }
        // 从*.bundle中查找资源
        bundle = [NSBundle bundleWithPath:[[NSBundle clLocalizedBundle] pathForResource:language ofType:@"lproj"]];
    }
    value = [bundle localizedStringForKey:key value:value table:nil];
    return [[NSBundle mainBundle] localizedStringForKey:key value:value table:nil];
}

@end
