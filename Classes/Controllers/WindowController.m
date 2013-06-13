//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "WindowController.h"

#import "OBMenuBarWindow.h"
#import "OAuthViewController.h"
#import "SORelativeDateTransformer.h"
#import "StreamListViewController.h"

@interface WindowController ()
@property (strong) NSViewController *currentViewController;
@property (strong) StreamListViewController *streamListViewController;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamListWasUpdated:) name:StreamListWasUpdatedNotification object:nil];

    // Set up our initial controllers and initialize and display the window
    // and status bar menu item.
    [self setupControllers];
    [self composeInterface];
}

#pragma mark Window Compositioning

- (void)setupControllers
{
    self.streamListViewController = [[StreamListViewController alloc] initWithNibName:@"StreamListView" bundle:nil];

    self.currentViewController = self.streamListViewController;
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
    [window setTitle:@""];
    [[window toolbarView] addSubview:self.titleBarView];

    // Make things pretty.
    [[self.preferencesButton cell] setBackgroundStyle:NSBackgroundStyleLowered];
    [[self.lastUpdatedLabel cell] setBackgroundStyle:NSBackgroundStyleLowered];
    [[self.statusLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

#pragma mark Notification Observers

- (void)streamListWasUpdated:(NSNotification *)notification
{
    StreamListViewController *object = [notification object];
    if ([object isKindOfClass:[StreamListViewController class]]) {
        // Update the interface, starting with the number of live streams.
        NSString *statusLabelString = [[NSString alloc] init];
        if ([object.streamArray count] == 1) {
            statusLabelString = [NSString stringWithFormat:@"%lu live stream", (unsigned long)[object.streamArray count]];
        } else {
            statusLabelString = [NSString stringWithFormat:@"%lu live streams", (unsigned long)[object.streamArray count]];
        }
        [[self statusLabel] setStringValue:statusLabelString];

        // Now update lastUpdatedLabel with the current date (relative).
        SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
        NSString *relativeDate = [relativeDateTransformer transformedValue:[NSDate date]];
        [[self lastUpdatedLabel] setStringValue:[NSString stringWithFormat:@"Last updated %@", relativeDate]];
    }
}

#pragma mark Interface Builder Actions

- (IBAction)showContextMenu:(NSButton *)sender
{
    [self.contextMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(14,26) inView:sender];
}

- (IBAction)showPreferences:(id)sender
{
    // If we have not created the window controller yet, create it now.
    if (!self.preferencesWindowController) {
        OAuthViewController *oauth = [[OAuthViewController alloc] init];
        NSArray *controllers = [NSArray arrayWithObjects:oauth, nil];
        self.preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Shiver Preferences", @"Preferences Window Title")];
    }

    [self.preferencesWindowController.window setLevel:NSFloatingWindowLevel];
    [self.preferencesWindowController showWindow:self];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
