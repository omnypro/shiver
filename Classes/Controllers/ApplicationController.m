//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StartAtLoginController.h"
#import "WindowController.h"

#import "ApplicationController.h"

@interface ApplicationController ()
@property (nonatomic, readwrite, strong) WindowController *windowController;
@end

@implementation ApplicationController

+ (ApplicationController *)sharedInstance
{
    return [NSApp delegate];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    WindowController *windowController = [[WindowController alloc] init];
    [self setWindowController:windowController];
    [self.windowController showWindow:self];

    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShiverAutoStart"]) {
        [loginController setStartAtLogin:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShiverAutoStart"];
    }
}

@end
