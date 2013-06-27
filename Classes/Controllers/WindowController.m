//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AboutWindowController.h"
#import "APIClient.h"
#import "EXTKeypathCoding.h"
#import "LoginRequiredView.h"
#import "NSColor+Hex.h"
#import "OBMenuBarWindow.h"
#import "StreamListViewController.h"
#import "User.h"

// Preferences-related imports.
#import "GeneralViewController.h"
#import "OAuthViewController.h"

#import "WindowController.h"

@interface WindowController () {
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_titleBarView;
    IBOutlet NSImageView *_statusImage;
    IBOutlet NSImageView *_userImage;
    IBOutlet NSButton *_preferencesButton;
    IBOutlet NSMenu *_contextMenu;
    IBOutlet NSMenuItem *_userMenuItem;
}

@property (nonatomic, strong) NSViewController *currentViewController;
@property (nonatomic, strong) StreamListViewController *streamListViewController;
@property (nonatomic, strong, readwrite) RHPreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) NSView *loginView;

@property (nonatomic, strong) AboutWindowController *aboutWindowController;
@property (nonatomic, strong) GeneralViewController *generalPreferences;
@property (nonatomic, strong) OAuthViewController *oauthPreferences;

@property (nonatomic, strong) APIClient *client;
@property (nonatomic, strong) User *user;

- (IBAction)showContextMenu:(NSButton *)sender;
- (IBAction)showProfile:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)showPreferences:(id)sender;
@end

@implementation WindowController

- (id)init
{
    self = [super init];
    if (self) { return [super initWithWindowNibName:@"Window"]; }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] setAllowsConcurrentViewDrawing:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestToOpenPreferences:) name:RequestToOpenPreferencesNotification object:nil];

    // Set up our initial controllers and initialize and display the window
    // and status bar menu item.
    [self composeInterface];

    // Do we have a user? Check for one by making self.user reactable. Try to
    // fetch the user from the API and when the value changes, show the
    // stream list.
    self.client = [APIClient sharedClient];
    RAC(self.user) = [[self.client fetchUser] deliverOn:[RACScheduler mainThreadScheduler]];
    [[[RACAbleWithStart(self.user) filter:^BOOL(User *user) {
        return (user != nil);
    }] map:^id(User *user) {
		NSLog(@"Application: Welcome %@!", user.name);
        return [[StreamListViewController alloc] initWithUser:user];
    }] toProperty:@keypath(self.currentViewController) onObject:self];

    // If self.user ever becomes nil, show the login required view.
    [[RACAbleWithStart(self.user) filter:^BOOL(User *user) {
        return (user == nil);
    }] subscribeNext:^(User *user) {
		NSLog(@"Application: We no longer have a user. :(");
        self.loginView = [LoginRequiredView init];
        [_masterView replaceSubview:self.currentViewController.view with:self.loginView];
    }];

    // Watch self.user and update the main interface appropriately.
    [RACAbleWithStart(self.user) subscribeNext:^(User *user) {
        if (user) {
            [_userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
            [_userImage setHidden:NO];
            [_userMenuItem setEnabled:YES];
            [_userMenuItem setTitle:[NSString stringWithFormat:@"Logged in as %@", self.user.name]];
        }
        else {
            [_userImage setHidden:YES];
            [_userMenuItem setEnabled:NO];
            [_userMenuItem setTitle:@"Not Logged In"];
            [_lastUpdatedLabel setHidden:YES];
            [_refreshButton setEnabled:NO];
            [_statusLabel setStringValue:@"Not logged in."];
            [_statusImage setImage:[NSImage imageNamed:@"BroadcastInactive"]];
        }
    }];
}

- (NSWindowController *)preferencesWindowController
{
    // If we have not created the window controller yet, create it now.
    if (_preferencesWindowController == nil) {
        _generalPreferences = [[GeneralViewController alloc] initWithNibName:@"GeneralView" bundle:nil];
        _oauthPreferences = [[OAuthViewController alloc] initWithUser:self.user];
        NSArray *controllers = @[ _generalPreferences, _oauthPreferences ];
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Shiver Preferences", @"Preferences Window Title")];
    }
    return _preferencesWindowController;
}

#pragma mark Window Compositioning

- (void)setCurrentViewController:(NSViewController *)viewController {
    if (_currentViewController == viewController) { return; }
    
    _currentViewController = viewController;
    [_currentViewController.view setFrame:_masterView.bounds];
    [_masterView addSubview:self.currentViewController.view];
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
    [[window toolbarView] addSubview:_titleBarView];

    // Make things pretty.
    [_statusLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];

    [_refreshButton setImage:[NSImage imageNamed:@"RefreshInactive"]];
    [_refreshButton setAlternateImage:[NSImage imageNamed:@"RefreshActive"]];

    [_preferencesButton setImage:[NSImage imageNamed:@"CogInactive"]];
    [_preferencesButton setAlternateImage:[NSImage imageNamed:@"CogActive"]];

    [[_statusImage cell] setBackgroundStyle:NSBackgroundStyleRaised];

    // Set the lastUpdatedLabel to a blank string when we initially compose
    // the interface. Reason being, I want a field with text in it to position
    // in Interface Builder.
    [_lastUpdatedLabel setHidden:YES];
    [_lastUpdatedLabel setTextColor:[NSColor colorWithHex:@"#9B9B9B"]];
}

#pragma mark Notification Observers

- (void)requestToOpenPreferences:(NSNotification *)notification
{
    [self showPreferences:notification.object];
}

#pragma mark Interface Builder Actions

- (IBAction)showContextMenu:(NSButton *)sender
{
    [_contextMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(14,26) inView:sender];
}

- (IBAction)showProfile:(id)sender {
    if (self.user && [_userMenuItem isEnabled]) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@", self.user.name]];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (IBAction)showAbout:(id)sender {
    self.aboutWindowController = [[AboutWindowController alloc] init];
    [self.aboutWindowController.window center];
    [self.aboutWindowController.window makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController.window setLevel:NSFloatingWindowLevel];
    [self.preferencesWindowController.window makeKeyAndOrderFront:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
