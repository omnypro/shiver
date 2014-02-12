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
#import "AccountManager.h"
#import "EmptyErrorView.h"
#import "HexColor.h"
#import "LoginRequiredView.h"
#import "NSView+Animations.h"
#import "Reachability.h"
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

@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) NSViewController *currentViewController;
@property (nonatomic, strong) StreamListViewController *streamListViewController;
@property (nonatomic, strong, readwrite) RHPreferencesWindowController *preferencesWindowController;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL isUIActive;
@property (nonatomic, strong) TwitchAPIClient *client;
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
    [self initializeInterface];
    [self initializeReachability];

    @weakify(self);

    RACSignal *readyAndReachable = [[[RACSignal combineLatest:@[[[AccountManager sharedManager] readySignal], [[AccountManager sharedManager] reachableSignal]]] and] distinctUntilChanged];
    RAC(self, isUIActive, @NO) = [readyAndReachable filter:^(NSNumber *value) { DDLogInfo(@"%@.", value); return [value boolValue]; }];

    [[readyAndReachable filter:^BOOL(NSNumber *value) {
        return ([value boolValue] == YES);
    }] subscribeNext:^(id x) {
        @strongify(self);
        self.loggedIn = YES;
        self.client = [TwitchAPIClient sharedClient];
        if (self.user == nil) {
            [[[self.client fetchUser] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(User *user) {
                DDLogInfo(@"Application (%@): We have a user. (%@)", [self class], user.name);
                self.user = user;
            } error:^(NSError *error) {
                DDLogError(@"Application (%@): We couldn't fetch a user. (%@)", [self class], [error localizedDescription]);
            }];
        }
    }];

    [[readyAndReachable filter:^BOOL(NSNumber *value) {
        return ([value boolValue] == NO);
    }] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): We do not have a credential.", [self class]);
        self.loggedIn = NO;
        self.client = nil;
    }];

    // Are we logged in? subscribe to changes to -loggedIn. If we are, try to
    // fetch the user from the API and when the value changes, then show the
    // stream list.
    [[[[[RACSignal combineLatest:@[ RACObserve(self, loggedIn), RACObserve(self, user) ] reduce:^(NSNumber *loggedIn, User *user) {
        BOOL isLoggedIn = [loggedIn boolValue];
        return @((isLoggedIn == YES) && (user != nil));
    }] distinctUntilChanged] filter:^BOOL(NSNumber *value) {
        return ([value boolValue] == YES);
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): Logged-in flag tripped. We have a user.", [self class]);
        DDLogInfo(@"Application (%@): Pushing a user to the stream list controller.", [self class]);
        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:self.user];
        [self setCurrentViewController:listController];
    }];
    [[[[RACObserve(self, loggedIn) distinctUntilChanged] filter:^BOOL(NSNumber *loggedIn) {
        return ([loggedIn boolValue] == NO);
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
		DDLogInfo(@"Application (%@): Logged-in flag tripped. We don't have a user.", [self class]);
        DDLogInfo(@"Application (%@): Pushing a -nil- user to the stream list controller.", [self class]);
        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:nil];
        [self setCurrentViewController:listController];
    }];

    // Watch -isUIActive and update the main interface appropriately.
    // NSDictionary *options = @{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName };
    // [self->_lastUpdatedLabel bind:NSHiddenBinding toObject:self withKeyPath:@"isUIActive" options:options];
    // [self->_sectionLabel bind:NSHiddenBinding toObject:self withKeyPath:@"isUIActive" options:@{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName }];
    // [self->_statusLabel bind:NSHiddenBinding toObject:self withKeyPath:@"isUIActive" options:@{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName }];
    // [self->_refreshButton bind:NSEnabledBinding toObject:self withKeyPath:@"isUIActive" options:@{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName }];
    // [self->_userImage bind:NSHiddenBinding toObject:self withKeyPath:@"isUIActive" options:@{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName }];
    // [self->_userMenuItem bind:NSEnabledBinding toObject:self withKeyPath:@"isUIActive" options:@{ NSContinuouslyUpdatesValueBindingOption: @YES, NSValueTransformerBindingOption: NSNegateBooleanTransformerName }];
    
    RACSignal *hasUserSignal = RACObserve(self, user);
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
        self.user = user;
    }];
    [self.loginPreferences.didLogoutSubject subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): We've been explicitly logged out. Update things.", [self class]);
        self.loggedIn = NO;
        self.user = nil;
    }];
}

- (void)initializeControllers
{
    self.aboutWindowController = [[AboutWindowController alloc] init];
    self.generalPreferences = [[GeneralViewController alloc] init];
    self.loginPreferences = [[LoginViewController alloc] init];
}

- (void)initializeReachability
{
    @weakify(self);

    [[[[[[AccountManager sharedManager] reachableSignal] distinctUntilChanged] filter:^BOOL(NSNumber *reachable) {
        return ([reachable boolValue] == NO);
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        NSString *title = @"Whoops! Something went wrong.";
        NSString *message = @"Looks like your internet is down.";
        DDLogError(@"Application (%@): Showing the error view with message, \"%@\"", [self class], message);
        self.errorView = [[EmptyErrorView init] errorViewWithTitle:title subTitle:message];
        [self->_masterView addSubview:self.errorView animated:YES];

        // Reset dat UI.
        self.isUIActive = NO;
    }];
    [[[[[[AccountManager sharedManager] reachableSignal] distinctUntilChanged] filter:^BOOL(NSNumber *reachable) {
        return ([reachable boolValue] == YES);
    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): Removing the error view.", [self class]);
        [self.errorView removeFromSuperviewAnimated:YES];
        self.errorView = nil;
        self.isUIActive = YES;
    }];
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

- (void)initializeInterface
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
