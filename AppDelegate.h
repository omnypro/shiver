//
//  AppDelegate.h
//  Shiver
//
//  Created by Bryan Veloso on 6/6/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OBMenuBarWindow;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSMenu *statusMenu;
@property (assign) IBOutlet OBMenuBarWindow *window;

@property (nonatomic, strong) NSStatusItem *statusBar;
@property (nonatomic, strong) NSPopover *popover;

@end
