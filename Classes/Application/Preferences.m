//
//  Preferences.m
//  Shiver
//
//  Created by Bryan Veloso on 6/29/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Preferences.h"

static NSString *const NotificationSetting = @"displayNotifications";
static NSString *const DisplayStreamCountSetting = @"displayStreamCount";
static NSString *const StreamListRefreshTimeSetting = @"streamListRefreshTime";
static NSString *const OpenStreamsInPopupSetting = @"openStreamsInPopup";

@implementation Preferences

+ (Preferences *)sharedPreferences
{
    static Preferences *_sharedPreferences = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedPreferences = [[Preferences alloc] init];
    });

    return _sharedPreferences;
}

- (BOOL)notificationsEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:NotificationSetting];
}

- (void)setNotificationsEnabled:(BOOL)notificationsEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:notificationsEnabled forKey:NotificationSetting];
    [userDefaults synchronize];
}

- (BOOL)streamCountEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:DisplayStreamCountSetting];
}

- (void)setStreamCountEnabled:(BOOL)streamCountEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:streamCountEnabled forKey:DisplayStreamCountSetting];
    [userDefaults synchronize];
}

- (NSTimeInterval)streamListRefreshTime
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults doubleForKey:StreamListRefreshTimeSetting];
}

- (void)setStreamListRefreshTime:(NSTimeInterval)streamListRefreshTime
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setDouble:(double)streamListRefreshTime forKey:StreamListRefreshTimeSetting];
    [userDefaults synchronize];
}

- (BOOL)streamPopupEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:OpenStreamsInPopupSetting];
}

- (void)setStreamPopupEnabled:(BOOL)streamPopupEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:streamPopupEnabled forKey:OpenStreamsInPopupSetting];
    [userDefaults synchronize];
}

@end
