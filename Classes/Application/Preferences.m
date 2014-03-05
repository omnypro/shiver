//
//  Preferences.m
//  Shiver
//
//  Created by Bryan Veloso on 6/29/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StartAtLoginController.h"

#import "Preferences.h"

static NSString *const IconVisibilitySetting = @"iconvVisibility";
static NSString *const AutoStartSetting = @"autoStart";
static NSString *const NotificationSetting = @"displayNotifications";
static NSString *const DisplayStreamCountSetting = @"displayStreamCount";
static NSString *const StreamListRefreshTimeSetting = @"streamListRefreshTime";

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

- (void)setupDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{
        IconVisibilitySetting: @0,
        AutoStartSetting: @(NO),
        NotificationSetting: @(YES),
        DisplayStreamCountSetting: @(YES),
        StreamListRefreshTimeSetting: @5,
    }];
    DDLogInfo(@"Application: The defaults have been set!");
}

- (NSNumber *)iconVisibility
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:IconVisibilitySetting];
}

- (void)setIconVisibility:(NSNumber *)iconVisibility
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:iconVisibility forKey:IconVisibilitySetting];
    [userDefaults synchronize];
}

- (BOOL)autoStartEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:AutoStartSetting];
}

- (void)setAutoStartEnabled:(BOOL)autoStartEnabled
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    [loginController setStartAtLogin:autoStartEnabled];
    [userDefaults setBool:YES forKey:AutoStartSetting];
    [userDefaults synchronize];
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

- (NSNumber *)streamListRefreshTime
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:StreamListRefreshTimeSetting];
}

- (void)setStreamListRefreshTime:(NSNumber *)streamListRefreshTime
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:streamListRefreshTime forKey:StreamListRefreshTimeSetting];
    [userDefaults synchronize];
}

@end
