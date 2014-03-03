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
@end

@implementation WindowController

- (void)initializeSignals
{
    @weakify(self);

    // Are we logged in? subscribe to changes to -loggedIn. If we are, try to
    // fetch the user from the API and when the value changes, then show the
    // stream list.
//    [[[[[RACSignal combineLatest:@[ RACObserve(self, loggedIn), RACObserve(self, user) ] reduce:^(NSNumber *loggedIn, User *user) {
//        BOOL isLoggedIn = [loggedIn boolValue];
//        return @((isLoggedIn == YES) && (user != nil));
//    }] distinctUntilChanged] filter:^BOOL(NSNumber *value) {
//        return ([value boolValue] == YES);
//    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
//        @strongify(self);
//        DDLogInfo(@"Application (%@): We have a user.", [self class]);
//        DDLogInfo(@"Application (%@): Pushing a user to the stream list controller.", [self class]);
//        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:self.user];
//        [self setCurrentViewController:listController];
//    }];
//    [[[[RACObserve(self, loggedIn) distinctUntilChanged] filter:^BOOL(NSNumber *loggedIn) {
//        return ([loggedIn boolValue] == NO);
//    }] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
//        @strongify(self);
//		DDLogInfo(@"Application (%@): We don't have a user.", [self class]);
//        DDLogInfo(@"Application (%@): Pushing a -nil- user to the stream list controller.", [self class]);
//        StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:nil];
//        [self setCurrentViewController:listController];
//    }];

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

@end
