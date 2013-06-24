//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "WindowController.h"

#import "APIClient.h"
#import "EmptyStreamListViewController.h"
#import "LoginRequiredViewController.h"
#import "NSColor+Hex.h"
#import "OBMenuBarWindow.h"
#import "SORelativeDateTransformer.h"
#import "StreamListViewController.h"
#import "User.h"

// Preferences-related imports.
#import "GeneralViewController.h"
#import "OAuthViewController.h"

@interface WindowController () {
@private
    dispatch_source_t _timer;
}

@property (strong) NSViewController *currentViewController;
@property (strong) EmptyStreamListViewController *emptyStreamListViewController;
@property (strong) LoginRequiredViewController *loginRequiredViewController;
@property (strong) StreamListViewController *streamListViewController;
@property (strong) NSDate *lastUpdatedTimestamp;

-(void) setupControllers;
-(void) swapViewController:(NSViewController *)viewController;
-(void) composeInterface;

- (void)startTimerForLastUpdatedLabel;
- (void)updateLastUpdatedLabel;

@end

@implementation WindowController

@synthesize preferencesWindowController = _preferencesWindowController;

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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestToOpenPreferences:) name:RequestToOpenPreferencesNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamListIsEmpty:) name:StreamListIsEmptyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamListWasUpdated:) name:StreamListWasUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userConnectedAccount:) name:UserDidConnectAccountNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDisconnectedAccount:) name:UserDidDisconnectAccountNotification object:nil];

    // Set up our initial controllers and initialize and display the window
    // and status bar menu item.
    [self setupControllers];
    [self composeInterface];
}

- (NSWindowController *)preferencesWindowController
{
    // If we have not created the window controller yet, create it now.
    if (_preferencesWindowController == nil) {
        GeneralViewController *general = [[GeneralViewController alloc] initWithNibName:@"GeneralView" bundle:nil];
        OAuthViewController *oauth = [[OAuthViewController alloc] initWithNibName:@"OAuthView" bundle:nil];
        NSArray *controllers = [NSArray arrayWithObjects:general, oauth, nil];
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Shiver Preferences", @"Preferences Window Title")];
    }
    return _preferencesWindowController;
}

#pragma mark Window Compositioning

- (void)setupControllers
{
    self.emptyStreamListViewController = [[EmptyStreamListViewController alloc] initWithNibName:@"EmptyStreamListView" bundle:nil];
    self.loginRequiredViewController = [[LoginRequiredViewController alloc] initWithNibName:@"LoginRequiredView" bundle:nil];
    self.streamListViewController = [[StreamListViewController alloc] initWithUser:nil];
    // self.streamListViewController = [[StreamListViewController alloc] initWithNibName:@"StreamListView" bundle:nil];

    if ([[APIClient sharedClient] isAuthenticated]) {
        self.currentViewController = self.streamListViewController;
    } else {
        self.currentViewController = self.loginRequiredViewController;
    }

    [self.currentViewController.view setFrame:self.masterView.bounds];
    [self.masterView addSubview:self.currentViewController.view];
}

- (void)swapViewController:(NSViewController *)viewController
{
    // Don't switch the view if it doesn't need switching.
    if (self.currentViewController == viewController) return;

    NSView *currentView = [self.currentViewController view];
    NSView *swappedView = [viewController view];

    [self.masterView replaceSubview:currentView with:swappedView];
    self.currentViewController = viewController;
    currentView = swappedView;

    [currentView setFrame:[self.masterView bounds]];
    [currentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
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
    [self.statusLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];

    [self.refreshButton setImage:[NSImage imageNamed:@"RefreshInactive"]];
    [self.refreshButton setAlternateImage:[NSImage imageNamed:@"RefreshActive"]];

    [self.preferencesButton setImage:[NSImage imageNamed:@"CogInactive"]];
    [self.preferencesButton setAlternateImage:[NSImage imageNamed:@"CogActive"]];

    [[self.statusImage cell] setBackgroundStyle:NSBackgroundStyleRaised];

    // Set the lastUpdatedLabel to a blank string when we initially compose
    // the interface. Reason being, I want a field with text in it to position
    // in Interface Builder.
    [self.lastUpdatedLabel setHidden:YES];
    [self.lastUpdatedLabel setTextColor:[NSColor colorWithHex:@"#9B9B9B"]];

    // The refresh button is disabled by default. We need to enable it if the
    // user is authenticated.
    if ([[APIClient sharedClient] isAuthenticated]) {
        [self.refreshButton setEnabled:YES];
    }

    // Are we logged in? Set the string value to the current username.
    [self.usernameLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];
    [User userWithBlock:^(User *user, NSError *error) {
        if (user) {
            [self.usernameLabel setStringValue:user.name];
            [self.userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
            [self.usernameLabel setHidden:NO];
            [self.userImage setHidden:NO];
        }
    }];
}

#pragma mark UI Update Methods

- (void)startTimerForLastUpdatedLabel
{
    // Schedule a timer to update `lastUpdatedLabel` every 30 seconds.
    // Keep a strong reference to _timer in ARC.
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 30.0 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{ [self updateLastUpdatedLabel]; });
    dispatch_resume(_timer);
}

- (void)updateLastUpdatedLabel
{
    [self.lastUpdatedLabel setHidden:NO];

    // Update `lastUpdatedLabel` with the current date (relative).
    SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
    NSString *relativeDate = [relativeDateTransformer transformedValue:self.lastUpdatedTimestamp];
    [self.lastUpdatedLabel setStringValue:[NSString stringWithFormat:@"Last updated %@", relativeDate]];
}

#pragma mark Notification Observers

- (void)requestToOpenPreferences:(NSNotification *)notification
{
    [self showPreferences:notification.object];
}

- (void)streamListIsEmpty:(NSNotification *)notification
{
    StreamListViewController *object = [notification object];
    if ([object isKindOfClass:[StreamListViewController class]]) {
        // Update the interface, swapping in the empty stream list view.
        [self swapViewController:self.emptyStreamListViewController];
        [self.statusImage setImage:[NSImage imageNamed:@"BroadcastInactive"]];
        [self.statusLabel setStringValue:@"No live streams"];
    }
}

- (void)streamListWasUpdated:(NSNotification *)notification
{
    StreamListViewController *object = [notification object];
    if ([object isKindOfClass:[StreamListViewController class]]) {
        // If the current view controller is `emptyStreamViewController`,
        // switch that out since we have results now.
        if (self.currentViewController == self.emptyStreamListViewController) {
            [self swapViewController:self.streamListViewController];
        }

        // Update the interface, starting with the number of live streams.
        NSString *statusLabelString = nil;
        if ([object.streamArray count] == 1) {
            statusLabelString = [NSString stringWithFormat:@"%lu live stream", (unsigned long)[object.streamArray count]];
        } else {
            statusLabelString = [NSString stringWithFormat:@"%lu live streams", (unsigned long)[object.streamArray count]];
        }
        [[self statusLabel] setStringValue:statusLabelString];

        self.lastUpdatedTimestamp = [NSDate date];
        [self updateLastUpdatedLabel];
        [self startTimerForLastUpdatedLabel];

        [self.statusImage setImage:[NSImage imageNamed:@"BroadcastActive"]];
    }
}

- (void)userConnectedAccount:(NSNotification *)notification
{
    OAuthViewController *object = [notification object];
    if ([object isKindOfClass:[OAuthViewController class]]) {

        [User userWithBlock:^(User *user, NSError *error) {
            if (user) {
                [self.usernameLabel setStringValue:user.name];
                [self.userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
                [self.usernameLabel setHidden:NO];
                [self.userImage setHidden:NO];
            }
        }];

        [self.refreshButton setEnabled:YES];
        [self swapViewController:self.streamListViewController];

        // Not sure we NEED to do this, but I guess it's just to make sure, eh?
        [self.streamListViewController loadStreamList];
    }
}

- (void)userDisconnectedAccount:(NSNotification *)notification
{
    OAuthViewController *object = [notification object];
    if ([object isKindOfClass:[OAuthViewController class]]) {
        // Ah, don't forget we have a timer. We should stop it.
        dispatch_source_cancel(_timer);

        // We've logged out. Show the login view.
        [self swapViewController:self.loginRequiredViewController];

        // Reset the interface.
        [self.usernameLabel setHidden:YES];
        [self.userImage setHidden:YES];
        [self.lastUpdatedLabel setHidden:YES];
        [self.refreshButton setEnabled:NO];
        [self.statusLabel setStringValue:@"Not logged in."];
        [self.statusImage setImage:[NSImage imageNamed:@"BroadcastInactive"]];
    }
}

#pragma mark Interface Builder Actions

- (IBAction)showContextMenu:(NSButton *)sender
{
    [self.contextMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(14,26) inView:sender];
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController.window setLevel:NSFloatingWindowLevel];
    [self.preferencesWindowController showWindow:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)refreshStreamList:(NSButton *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestToUpdateStreamNotification object:self userInfo:nil];
}

@end
