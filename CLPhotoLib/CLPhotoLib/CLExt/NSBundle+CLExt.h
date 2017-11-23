//
//  NSBundle+CLExt.h
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/1.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (CLExt)

FOUNDATION_EXTERN NSString *CLString(NSString *key);

+ (instancetype)clLocalizedBundle;

+ (NSString *)clLocalizedStringForKey:(NSString *)key;

+ (NSString *)clLocalizedStringForKey:(NSString *)key value:(NSString *)value;

@end

