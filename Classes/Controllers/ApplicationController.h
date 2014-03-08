//
//  ApplicationController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <RHPreferences/RHPreferences.h>
#import <ServiceManagement/ServiceManagement.h>

#import "ShiverApplication.h"

@class MainWindowController;

@interface ApplicationController : NSObject <ShiverApplicationDelegate> {}

@property (nonatomic, readonly, strong) MainWindowController *windowController;
@property (nonatomic, readonly, strong) RHPreferencesWindowController *preferencesWindowController;

@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSStatusItem *statusItem;

+ (ApplicationController *)sharedInstance;

@end
