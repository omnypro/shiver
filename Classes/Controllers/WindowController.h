//
//  WindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RHPreferences/RHPreferences.h>

@class OBMenuBarWindow;

@interface WindowController : NSWindowController

@property (nonatomic, readonly) RHPreferencesWindowController *preferencesWindowController;

@end
