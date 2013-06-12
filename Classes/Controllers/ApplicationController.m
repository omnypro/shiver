//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "ApplicationController.h"

#import "WindowController.h"
#import "User.h"

@interface ApplicationController ()
@property (nonatomic, strong) WindowController *windowController;
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

    [User fetchUser];
}

@end
