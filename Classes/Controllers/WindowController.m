//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "OBMenuBarWindow.h"

#import "WindowController.h"

@interface WindowController ()
-(void) setupControllers;
-(void) composeInterface;
@end

@implementation WindowController

- (id)init
{
    self = [super init];
    if (self) {
        return [super initWithWindowNibName:@"Window"];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] setAllowsConcurrentViewDrawing:YES];

    // Set up our initial controllers.
    [self setupControllers];
    
    // Initialize and display the window and status bar menu item.
    [self composeInterface];
}

#pragma mark Window Compositioning

- (void)setupControllers
{
    
}

- (void)composeInterface
{
    OBMenuBarWindow *window = (OBMenuBarWindow *)[self window];
    [window setHasMenuBarIcon:YES];
    [window setMenuBarIcon:[NSImage imageNamed:NSImageNameActionTemplate]];
    [window setHighlightedMenuBarIcon:[NSImage imageNamed:NSImageNameActionTemplate]];
    [window setAttachedToMenuBar:YES];
    [window setTitle:@""];
}

@end
