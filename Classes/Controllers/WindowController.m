//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "WindowController.h"

#import "OBMenuBarWindow.h"
#import "StreamViewController.h"

@interface WindowController ()
@property (strong) NSViewController *currentViewController;
@property (strong) StreamViewController *streamViewController;

-(void) setupControllers;
-(void) composeInterface;
-(void) composeTitleBar;
@end

@implementation WindowController

@synthesize masterView = _masterView;

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
    self.streamViewController = [[StreamViewController alloc] initWithNibName:@"StreamView" bundle:nil];

    self.currentViewController = self.streamViewController;
    [self.currentViewController.view setFrame:self.masterView.bounds];
    [self.masterView addSubview:self.currentViewController.view];
}

- (void)composeInterface
{
    OBMenuBarWindow *window = (OBMenuBarWindow *)[self window];
    [window setHasMenuBarIcon:YES];
    [window setMenuBarIcon:[NSImage imageNamed:@"StatusBarIcon"]];
    [window setHighlightedMenuBarIcon:[NSImage imageNamed:@"StatusBarIconInverted"]];
    [window setAttachedToMenuBar:YES];

    // Compose our own title bar.
    [self composeTitleBar];
}

- (void)composeTitleBar
{
    OBMenuBarWindow *window = (OBMenuBarWindow *)[self window];
    [window setTitle:@""];
    [[window toolbarView] addSubview:self.titleBarView];
    [[self.statusLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

@end
