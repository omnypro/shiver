//
//  AppDelegate.m
//  Shiver
//
//  Created by Bryan Veloso on 6/6/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "OBMenuBarWindow.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize and display the window and status bar menu item.
    [self.window setMenuBarIcon:[NSImage imageNamed:NSImageNameActionTemplate]];
    [self.window setHighlightedMenuBarIcon:[NSImage imageNamed:NSImageNameActionTemplate]];
    [self.window setHasMenuBarIcon:YES];
    [self.window setAttachedToMenuBar:YES];

    // Initialize and display the status bar menu item.
    // self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    // [self.statusBar setTitle:@"Shiver"];
    // [self.statusBar setMenu:self.statusMenu];
    // [self.statusBar setHighlightMode:YES];

    // @@@ TODO: Set an image.
    // [self.statusBar setImage];
}

@end
