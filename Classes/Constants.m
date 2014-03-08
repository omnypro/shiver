//
//  Constants.m
//  Shiver
//
//  Created by Bryan Veloso on 6/12/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Constants.h"

NSString *const ShiverIdentifier = @"com.revyver.Shiver";
NSString *const ShiverHelperIdentifier = @"com.revyver.ShiverHelper";
NSString *const RequestToOpenPreferencesNotification = @"com.revyver.Shiver.RequestToOpenPreferencesNotification";
NSString *const RequestToOpenWindowNotification = @"com.revyver.Shiver.RequestToOpenWindowNotification";

#ifdef DEBUG
const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
const int ddLogLevel = LOG_LEVEL_WARN;
#endif

@implementation Constants

@end
