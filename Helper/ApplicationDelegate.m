//
//  ApplicationDelegate.m
//  ShiverHelper
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "ApplicationDelegate.h"

@implementation ApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // This string takes you from
    // MyGreat.App/Contents/Library/LoginItems/MyHelper.app to MyGreat.App
    // This is an obnoxious but dynamic way to do this since that specific
    // subpath is required.
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];

    // This gets the binary executable within your main application.
    NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath];
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
    [NSApp terminate:nil];
}

@end
