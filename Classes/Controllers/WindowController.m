//
//  WindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTKeypathCoding.h>
#import <EXTScope.h>

#import "AboutWindowController.h"
#import "HexColor.h"
#import "LoginRequiredView.h"
#import "StreamListViewController.h"
#import "TwitchAPIClient.h"
#import "User.h"

// Preferences-related imports.
#import "GeneralViewController.h"
#import "LoginViewController.h"

#import "WindowController.h"

@interface WindowController () {
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_headerView;
    IBOutlet NSView *_footerView;
    IBOutlet NSImageView *_userImage;
    IBOutlet NSButton *_preferencesButton;
    IBOutlet NSMenu *_contextMenu;
    IBOutlet NSMenuItem *_userMenuItem;
}

@property (nonatomic, strong) NSViewController *currentViewController;
@property (nonatomic, strong) StreamListViewController *streamListViewController;
@property (nonatomic, strong, readwrite) RHPreferencesWindowController *preferencesWindowController;
@property (nonatomic, strong) NSView *loginView;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) AFOAuthCredential *credential;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) AboutWindowController *aboutWindowController;
@property (nonatomic, strong) GeneralViewController *generalPreferences;
@property (nonatomic, strong) LoginViewController *loginPreferences;

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
    [self.window setAllowsConcurrentViewDrawing:YES];
    [self.window setBackgroundColor:[NSColor colorWithHexString:@"#222222" alpha:1]];
    [self.window setLevel:NSFloatingWindowLevel];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(close) name:NSApplicationDidResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(close) name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestToOpenPreferences:) name:RequestToOpenPreferencesNotification object:nil];

    // Set up our initial controllers and initialize and display the window
    // and status bar menu item.
    [self initializeControllers];
    [self composeInterface];

    @weakify(self);

    self.credential = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    [[[RACAbleWithStart(self.credential) distinctUntilChanged] filter:^BOOL(AFOAuthCredential *credential) {
        return (credential != nil);
    }] subscribeNext:^(AFOAuthCredential *credential) {
        @strongify(self);
        DDLogInfo(@"Application (%@): We have a credential.", [self class]);
        self.loggedIn = YES;
        self.client = [TwitchAPIClient sharedClient];
        if (self.user == nil) {
            [[[self.client fetchUser] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(User *user) {
                DDLogInfo(@"Application (%@): We have a user. (%@)", [self class], user.name);
                self.user = user;
            }];
        }
    }];
    [[[RACAbleWithStart(self.credential) distinctUntilChanged] filter:^BOOL(AFOAuthCredential *credential) {
        return (credential == nil);
    }] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): We do not have a credential.", [self class]);
        self.loggedIn = NO;
        self.client = nil;
    }];

    // Are we logged in? subscribe to changes to -loggedIn. If we are, try to
    // fetch the user from the API and when the value changes, then show the
    // stream list.
    [[[[RACSignal combineLatest:@[ RACAbleWithStart(self.loggedIn), RACAbleWithStart(self.user) ] reduce:^(NSNumber *loggedIn, User *user) {
        BOOL isLoggedIn = [loggedIn boolValue];
        return @((isLoggedIn == YES) && (user != nil));
    }] distinctUntilChanged] filter:^BOOL(NSNumber *value) {
        return ([value boolValue] == YES);
    }] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): Logged-in flag tripped. We have a user.", [self class]);
        DDLogInfo(@"Application (%@): Pushing a user to the stream list controller.", [self class]);
        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:self.user];
        [self setCurrentViewController:listController];
    }];
    [[[RACAbleWithStart(self.loggedIn) distinctUntilChanged] filter:^BOOL(NSNumber *loggedIn) {
        return ([loggedIn boolValue] == NO);
    }] subscribeNext:^(id x) {
        @strongify(self);
		DDLogInfo(@"Application (%@): Logged-in flag tripped. We don't have a user.", [self class]);
        DDLogInfo(@"Application (%@): Pushing a -nil- user to the stream list controller.", [self class]);
        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:nil];
        [self setCurrentViewController:listController];
    }];

    // Watch -isHidden and update the main interface appropriately.
    [self->_lastUpdatedLabel rac_bind:NSHiddenBinding toObject:self withNegatedKeyPath:@keypath(self.loggedIn)];
    [self->_sectionLabel rac_bind:NSHiddenBinding toObject:self withNegatedKeyPath:@keypath(self.loggedIn)];
    [self->_statusLabel rac_bind:NSHiddenBinding toObject:self withNegatedKeyPath:@keypath(self.loggedIn)];
    [self->_refreshButton rac_bind:NSEnabledBinding toObject:self withKeyPath:@keypath(self.loggedIn)];
    [self->_userImage rac_bind:NSHiddenBinding toObject:self withNegatedKeyPath:@keypath(self.loggedIn)];
    [self->_userMenuItem rac_bind:NSEnabledBinding toObject:self withKeyPath:@keypath(self.loggedIn)];

    RACSignal *hasUserSignal = RACAbleWithStart(self.user);
    [hasUserSignal subscribeNext:^(User *user) {
        @strongify(self);
        if (user) {
            [_statusLabel setStringValue:@"Welcome"];
            [_userImage setImage:[[NSImage alloc] initWithContentsOfURL:user.logoImageURL]];
            [_userMenuItem setTitle:[NSString stringWithFormat:@"Logged in as %@", self.user.name]];
        }
        else {
            [_statusLabel setStringValue:@"Not logged in"];
            [_userImage setImage:nil];
            [_userMenuItem setTitle:@"Not logged in"];
        }
    }];

    // Subscribe to -didLoginSubject and -didLogoutSubject so that we may react
    // to changes in the login system (logging in, logging out, etc.).
    [self.loginPreferences.didLoginSubject subscribeNext:^(RACTuple *tuple) {
        @strongify(self);
        RACTupleUnpack(AFOAuthCredential *credential, User *user) = tuple;
        DDLogInfo(@"Application (%@): We've been explicitly logged in. Welcome %@ (%@).", [self class], user.name, credential.accessToken);
        self.loggedIn = YES;
        self.credential = credential;
        self.user = user;
    }];
    [self.loginPreferences.didLogoutSubject subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): We've been explicitly logged out. Update things.", [self class]);
        self.loggedIn = NO;
        self.credential = nil;
        self.user = nil;
    }];
}

- (void)initializeControllers
{
    self.aboutWindowController = [[AboutWindowController alloc] init];
    self.generalPreferences = [[GeneralViewController alloc] init];
    self.loginPreferences = [[LoginViewController alloc] init];
}

- (NSWindowController *)preferencesWindowController
{
    // If we have not created the window controller yet, create it now.
    if (_preferencesWindowController == nil) {
        NSArray *controllers = @[ self.generalPreferences, self.loginPreferences ];
        _preferencesWindowController = [[RHPreferencesWindowController alloc] initWithViewControllers:controllers andTitle:NSLocalizedString(@"Shiver Preferences", @"Preferences Window Title")];
    }
    return _preferencesWindowController;
}

#pragma mark - Window Compositioning

- (void)setCurrentViewController:(NSViewController *)viewController {
    if (_currentViewController == viewController) { return; }
    
    _currentViewController = viewController;
    [_currentViewController.view setFrame:_masterView.bounds];
    [_masterView addSubview:self.currentViewController.view];
}

- (void)composeInterface
{
    // Make things pretty.
    [_sectionLabel setTextColor:[NSColor colorWithHexString:@"#666666" alpha:1]];
    [_statusLabel setTextColor:[NSColor colorWithHexString:@"#7F7F7F" alpha:1]];

    // Set the lastUpdatedLabel to a blank string when we initially compose
    // the interface. Reason being, I want a field with text in it to position
    // in Interface Builder.
    [_lastUpdatedLabel setHidden:YES];
    [_lastUpdatedLabel setTextColor:[NSColor colorWithHexString:@"#4F4F4F" alpha:1]];

    [_refreshButton setImage:[NSImage imageNamed:@"RefreshInactive"]];
    [_refreshButton setAlternateImage:[NSImage imageNamed:@"RefreshActive"]];
    [_preferencesButton setImage:[NSImage imageNamed:@"CogInactive"]];
    [_preferencesButton setAlternateImage:[NSImage imageNamed:@"CogActive"]];
}

#pragma mark - Notification Observers

- (void)requestToOpenPreferences:(NSNotification *)notification
{
    [self showPreferences:notification.object];
}

#pragma mark - Interface Builder Actions

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
