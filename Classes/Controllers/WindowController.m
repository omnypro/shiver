//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "WindowController.h"

#import "APIClient.h"
#import "EXTKeypathCoding.h"
#import "LoginRequiredView.h"
#import "NSColor+Hex.h"
#import "OBMenuBarWindow.h"
#import "SORelativeDateTransformer.h"
#import "StreamListViewController.h"
#import "User.h"

// Preferences-related imports.
#import "GeneralViewController.h"
#import "OAuthViewController.h"

@interface WindowController () {
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_titleBarView;
    IBOutlet NSImageView *_statusImage;
    IBOutlet NSTextField *_usernameLabel;
    IBOutlet NSImageView *_userImage;
    IBOutlet NSTextField *_lastUpdatedLabel;
    IBOutlet NSButton *_preferencesButton;
    IBOutlet NSMenu *_contextMenu;

@private
    dispatch_source_t _timer;
}

@property (nonatomic, strong) NSViewController *currentViewController;
@property (nonatomic, strong) StreamListViewController *streamListViewController;
@property (nonatomic, strong, readwrite) RHPreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) NSView *loginView;

@property (nonatomic, strong) GeneralViewController *generalPreferences;
@property (nonatomic, strong) OAuthViewController *oauthPreferences;

@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) APIClient *client;
@property (nonatomic, strong) User *user;

- (void)swapViewController:(NSViewController *)viewController;
- (void)composeInterface;

- (void)startTimerForLastUpdatedLabel;
- (void)updateLastUpdatedLabel;

- (IBAction)showContextMenu:(NSButton *)sender;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamListIsEmpty:) name:StreamListIsEmptyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamListWasUpdated:) name:StreamListWasUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userConnectedAccount:) name:UserDidConnectAccountNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDisconnectedAccount:) name:UserDidDisconnectAccountNotification object:nil];

    // Set up our initial controllers and initialize and display the window
    // and status bar menu item.
    [self composeInterface];

    // Do we have a user? Check for one by making self.user reactable. Try to
    // fetch the user from the API and when the value changes, show the
    // stream list.
    self.client = [APIClient sharedClient];
    RAC(self.user) = [[self.client fetchUser] deliverOn:RACScheduler.mainThreadScheduler];
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

- (void)swapViewController:(NSViewController *)viewController
{
    // Don't switch the view if it doesn't need switching.
    if (self.currentViewController == viewController) return;

    NSView *currentView = [self.currentViewController view];
    NSView *swappedView = [viewController view];

    [_masterView replaceSubview:currentView with:swappedView];
    self.currentViewController = viewController;
    currentView = swappedView;

    [currentView setFrame:[_masterView bounds]];
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

    // Are we logged in? Set the string value to the current username.
    [_usernameLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];
    [User userWithBlock:^(User *user, NSError *error) {
        if (user) {
            [_usernameLabel setStringValue:user.name];
            [_userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
            [_usernameLabel setHidden:NO];
            [_userImage setHidden:NO];
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
    [_lastUpdatedLabel setHidden:NO];

    // Update `lastUpdatedLabel` with the current date (relative).
    SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
    NSString *relativeDate = [relativeDateTransformer transformedValue:self.lastUpdatedTimestamp];
    [_lastUpdatedLabel setStringValue:[NSString stringWithFormat:@"Last updated %@", relativeDate]];
}

#pragma mark Notification Observers

- (void)requestToOpenPreferences:(NSNotification *)notification
{
    [self showPreferences:notification.object];
}

- (void)userConnectedAccount:(NSNotification *)notification
{
    OAuthViewController *object = [notification object];
    if ([object isKindOfClass:[OAuthViewController class]]) {

        [User userWithBlock:^(User *user, NSError *error) {
            if (user) {
                [_usernameLabel setStringValue:user.name];
                [_userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
                [_usernameLabel setHidden:NO];
                [_userImage setHidden:NO];
            }
        }];

        [_refreshButton setEnabled:YES];
        [self swapViewController:self.streamListViewController];
    }
}

- (void)userDisconnectedAccount:(NSNotification *)notification
{
    OAuthViewController *object = [notification object];
    if ([object isKindOfClass:[OAuthViewController class]]) {
        // Ah, don't forget we have a timer. We should stop it.
        dispatch_source_cancel(_timer);

        // Reset the interface.
        [_usernameLabel setHidden:YES];
        [_userImage setHidden:YES];
        [_lastUpdatedLabel setHidden:YES];
        [_refreshButton setEnabled:NO];
        [_statusLabel setStringValue:@"Not logged in."];
        [_statusImage setImage:[NSImage imageNamed:@"BroadcastInactive"]];
    }
}

#pragma mark Interface Builder Actions

- (IBAction)showContextMenu:(NSButton *)sender
{
    [_contextMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(14,26) inView:sender];
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController.window setLevel:NSFloatingWindowLevel];
    [self.preferencesWindowController showWindow:sender];
    [NSApp activateIgnoringOtherApps:YES];
}

@end
