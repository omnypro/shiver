//
//  Preferences.h
//  Shiver
//
//  Created by Bryan Veloso on 6/29/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Preferences : NSObject

@property (nonatomic, assign) BOOL notificationsEnabled;
@property (nonatomic, assign) BOOL streamCountEnabled;
@property (nonatomic, assign) NSTimeInterval streamListRefreshTime;
@property (nonatomic, assign) BOOL streamPopupEnabled;

+ (Preferences *)sharedPreferences;

@end
