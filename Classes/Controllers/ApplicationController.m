//
//  ApplicationController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Preferences.h"
#import "StartAtLoginController.h"
#import "WindowController.h"

#import "ApplicationController.h"

@interface ApplicationController ()
@property (nonatomic, strong) StartAtLoginController *loginController;
@property (nonatomic, readwrite, strong) WindowController *windowController;
@property (nonatomic, strong) Preferences *preferences;
@end

@implementation ApplicationController

+ (ApplicationController *)sharedInstance
{
    return [NSApp delegate];
}

- (id)init
{
	self = [super init];
	if (self == nil) { return nil; }

    _preferences = [Preferences sharedPreferences];
    _loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    _windowController = [[WindowController alloc] init];
    return self;
}

- (void)awakeFromNib
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setAction:@selector(toggleWindow:)];
    [self.statusItem setImage:[NSImage imageNamed:@"StatusItem"]];
    [self.statusItem setAlternateImage:[NSImage imageNamed:@"StatusItemAlternate"]];
    [self.statusItem setHighlightMode:YES];
}

- (IBAction)toggleWindow:(id)sender
{
    if ([self.windowController.window isVisible]) {
        [self.windowController.window close];
    }
    else {
        NSDisableScreenUpdates();
        NSImage *image = [self.statusItem image];
        NSImage *alternateImage = [self.statusItem alternateImage];
        NSString *title = [self.statusItem title];
        id target = [self.statusItem target];
        SEL action = [self.statusItem action];
        NSView *dummyView = [[NSView alloc] initWithFrame:NSZeroRect];
        self.statusItem.view = dummyView;
        // A bit of a cheat, but we know here that the last click was in the
        // status item (remember that all menu items are rendered as windows).
        NSWindow *statusItemWindow = [dummyView window];

        // Apparently setting a view has a number of nasty consequences,
        // so let's repatch everything here.
        [self.statusItem setView:nil];
        [self.statusItem setImage:image];
        [self.statusItem setAlternateImage:alternateImage];
        [self.statusItem setHighlightMode:YES];
        [self.statusItem setTarget:target];
        [self.statusItem setTitle:title];
        [self.statusItem setAction:action];
        NSEnableScreenUpdates();

        NSRect statusItemScreenRect = [statusItemWindow frame];
        CGFloat midX = NSMidX(statusItemScreenRect);
        CGFloat windowWidth = NSWidth([self.windowController.window frame]);
        CGFloat windowHeight = NSHeight([self.windowController.window frame]);

        // There is a 22 point difference when the window is offset from a
        // status item with a count versus without one. We need to take that
        // into consideration.
        float offset = -10;
        if (self.preferences.streamCountEnabled) { offset = 12; }

		NSRect windowFrame = NSMakeRect(floor(midX - (windowWidth / 2.0)), floor(NSMinY(statusItemScreenRect) - windowHeight - [[NSApp mainMenu] menuBarHeight]) + offset, windowWidth, windowHeight);

        [self.windowController.window setFrameOrigin:windowFrame.origin];
        [self.windowController.window makeKeyAndOrderFront:sender];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Preload the window.
    (void)self.windowController.window;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShiverAutoStart"]) {
        [self.loginController setStartAtLogin:YES];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShiverAutoStart"];
    }
}

@end
