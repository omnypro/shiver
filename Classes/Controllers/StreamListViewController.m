//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "TwitchAPIClient.h"
#import "Channel.h"
#import "EmptyErrorView.h"
#import "HexColor.h"
#import "NSView+Animations.h"
#import "JAListView.h"
#import "LoadingView.h"
#import "LoginRequiredView.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "StatusItemView.h"
#import "Stream.h"
#import "StreamListViewItem.h"
#import "User.h"
#import "WindowController.h"

#import "StreamListViewController.h"

@interface StreamListViewController () {
    IBOutlet JAListView *_listView;
}

@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSView *loginView;
@property (nonatomic, strong) StatusItemView *statusItem;
@property (nonatomic, strong) RACCommand *refreshCommand;
@property (nonatomic, strong) WindowController *windowController;

@property (nonatomic, strong) AFOAuthCredential *credential;
@property (nonatomic, strong) TwitchAPIClient *client;
@property (nonatomic, strong) NSArray *streamList;
@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) User *user;

@property (nonatomic, assign) BOOL loggedIn;
@property (atomic) BOOL showingError;
@property (atomic) BOOL showingEmpty;
@property (atomic) BOOL showingLoading;
@property (atomic) NSString *showingErrorMessage;

- (void)sendNewStreamNotificationToUser:(NSSet *)newSet;
@end

@implementation StreamListViewController

- (id)initWithUser:(User *)user
{
    self = [super initWithNibName:@"StreamListView" bundle:nil];
    if (self == nil) { return nil; }

    self.statusItem = [[NSApp delegate] statusItem];
    self.preferences = [Preferences sharedPreferences];
    self.user = user;
    self.windowController = [[NSApp delegate] windowController];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    self.loginView = [LoginRequiredView init];
    self.loadingView = [[LoadingView init] loadingViewWithProgressIndicator];

    [self setUpViewSignals];
    [self setUpDataSignals];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setCanCallDataSourceInParallel:YES];
    [_listView setConditionallyUseLayerBacking:YES];
}

- (void)setUpViewSignals
{
    @weakify(self);

    self.refreshCommand = [RACCommand command];
    self.windowController.refreshButton.rac_command = self.refreshCommand;
    [self.refreshCommand subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"Application (%@): Request to manually refresh the stream list.", [self class]);
        self.client = [TwitchAPIClient sharedClient];
        self.showingLoading = YES;
    }];

    // Watch to see if the user has asked to see the stream count in the status
    // bar (via its preference) and set the status item's title to the number
    // of live streams.
    [[[RACAbleWithStart(self.preferences.streamCountEnabled) deliverOn:[RACScheduler scheduler]] filter:^BOOL(id value) {
        return ([value boolValue] == YES);
    }] subscribeNext:^(id x) {
        @strongify(self);
        if ([self.streamList count] > 0) { [self.statusItem setTitle:[NSString stringWithFormat:@"%lu", [self.streamList count]]]; }
        else { [self.statusItem setTitle:@""]; }
    }];
    [[[RACAbleWithStart(self.preferences.streamCountEnabled) deliverOn:[RACScheduler scheduler]] filter:^BOOL(id value) {
        return ([value boolValue] != YES);
    }] subscribeNext:^(id x) {
        @strongify(self);
        [self.statusItem setTitle:@""];
    }];

    // Watch the stream list for changes and enable or disable UI elements
    // based on those values.
    [[RACAbleWithStart(self.streamList) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *array) {
        @strongify(self);
        if ([array count] > 0) {
            // Set the status item's title to the number of live streams if the
            // user has asked for it in the preferences.
            if (self.preferences.streamCountEnabled) {
                [self.statusItem setTitle:[NSString stringWithFormat:@"%lu", [self.streamList count]]];
            }

            [self.windowController.refreshButton setEnabled:YES];

            // Update the string based on the number of streams that are live.
            NSString *singularCount = [NSString stringWithFormat:@"%lu live stream", [array count]];
            NSString *pluralCount = [NSString stringWithFormat:@"%lu live streams", [array count]];
            if ([array count] == 1) { [self.windowController.statusLabel setStringValue:singularCount]; }
            else if ([array count] > 1) { [self.windowController.statusLabel setStringValue:pluralCount]; }
            else { [self.windowController.statusLabel setStringValue:@"No live streams"]; }
        }
        else {
            [self.statusItem setTitle:@""];
            [self.windowController.refreshButton setEnabled:NO];
            [self.windowController.statusLabel setStringValue:@"No live streams"];
        }
    }];

    // Updated the lastUpdated label every 30 seconds.
    NSTimeInterval lastUpdatedInterval = 30.0;
    [[[[RACAbleWithStart(self.streamList) filter:^BOOL(NSArray *array) {
        return (array != nil);
    }] map:^id(id value) {
        return [RACSignal interval:lastUpdatedInterval];
    }] switchToLatest] subscribeNext:^(NSArray *array) {
        @strongify(self);
        DDLogVerbose(@"Application (%@): Updating the last updated label (on interval).", [self class]);
        if (array != nil) { [self updateLastUpdatedLabel]; }
    }];

    // Show or hide the loading view.
    [[[RACAble(self.showingLoading) distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingLoading) {
         @strongify(self);
         BOOL isShowingLoading = [showingLoading boolValue];
         if (isShowingLoading) {
             DDLogInfo(@"Application (%@): Showing the loading view.", [self class]);
             [self.loadingView.progressIndicator startAnimation:self];
             [self.view addSubview:self.loadingView positioned:NSWindowAbove relativeTo:nil];
         }
         else {
             DDLogInfo(@"Application (%@): Removing the loading view.", [self class]);
             [self.loadingView removeFromSuperviewAnimated:YES];
             [self.loadingView.progressIndicator stopAnimation:self];
             self.loadingView = nil;
         }
     }];

    // Show or hide the empty view.
    [[[RACAble(self.showingEmpty) distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingEmpty) {
        @strongify(self);
        BOOL isShowingEmpty = [showingEmpty boolValue];
        if (isShowingEmpty && !self.showingError){
            DDLogInfo(@"Application (%@): Showing the empty view.", [self class]);
            NSString *title = @"Looks like you've got nothing to watch.";
            NSString *subTitle = @"Why don't you follow some new streamers?";
            self.emptyView = [[EmptyErrorView init] emptyViewWithTitle:title subTitle:subTitle];
            [self.view addSubview:self.emptyView animated:YES];
        } else {
            DDLogInfo(@"Application (%@): Removing the empty view.", [self class]);
            [self.emptyView removeFromSuperviewAnimated:YES];
            self.emptyView = nil;
        }
    }];

    // Show or hide the error view.
    [[[RACAble(self.showingError) distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingError) {
        @strongify(self);
        BOOL isShowingError = [showingError boolValue];
        if (isShowingError) {
            // Don't show the empty or loading views if there's an error.
            self.showingEmpty = NO;
            self.showingLoading = NO;
            NSString *title = @"Whoops! Something went wrong.";
            NSString *message = self.showingErrorMessage ? self.showingErrorMessage : @"Undefined error.";
            DDLogError(@"Application (%@): Showing the error view with message \"%@\"", [self class], message);
            self.errorView = [[EmptyErrorView init] errorViewWithTitle:title subTitle:message];
            [self.view addSubview:self.errorView animated:YES];
        }
        else {
            DDLogInfo(@"Application (%@): Removing the error view.", [self class]);
            [self.errorView removeFromSuperviewAnimated:YES];
            self.errorView = nil;
            self.showingErrorMessage = nil;
        }
    }];

    // Show or hide the login view.
    [[[RACAble(self.loggedIn) distinctUntilChanged]
      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingLogin) {
        @strongify(self);
        BOOL isShowingLogin = [showingLogin boolValue];
        if (!isShowingLogin) {
            DDLogInfo(@"Application (%@): Showing the login view.", [self class]);
            // Don't show any of the other views if we're going to show login.
            self.errorView = NO;
            self.loadingView = NO;
            [self.view addSubview:self.loginView animated:YES];

            // A little extra work, make sure the status item's title is nil.
            [self.statusItem setTitle:@""];
        }
        else {
            DDLogInfo(@"Application (%@): Removing the login view.", [self class]);
            [self.loginView removeFromSuperviewAnimated:YES];
        }
    }];
}

- (void)setUpDataSignals
{
    @weakify(self);

    // Watch for `user` to change or be populated. If it is, start the process
    // off by spawning the API client.
    [[RACAbleWithStart(self.user) filter:^BOOL(id value) {
        return (value != nil);
    }] subscribeNext:^(User *user) {
        DDLogInfo(@"Application (%@): Loading client for %@.", [self class], user.name);
        @strongify(self);
        self.client = [TwitchAPIClient sharedClient];
        self.loggedIn = YES;
        [self.windowController.statusLabel setStringValue:@"Loading..."];
    }];

    // We pass a nil user to this controller in order to "reset" the interface.
    // We'll watch that value, filter then reset the interface.
    [[RACAbleWithStart(self.user) filter:^BOOL(id value) {
        return (value == nil);
    }] subscribeNext:^(User *user) {
        self.client = nil;
        self.loggedIn = NO;
        self.streamList = nil;
    }];

    // Watch for `client` to change or be populated. If so, fetch the stream
    // list and assign it.
    [[[RACAbleWithStart(self.client) filter:^BOOL(id value) {
        return (value != nil);
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        @strongify(self);
        self.showingLoading = YES;
        [[[self.client fetchStreamList]
          deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *streamList) {
            DDLogInfo(@"Application (%@): Fetching the stream list.", [self class]);
            @strongify(self);
            self.streamList = streamList;
            self.showingError = NO;
        } error:^(NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
            self.showingErrorMessage = [error localizedDescription];
            self.showingError = YES;
        }];
    }];

    // When the stream list gets changed, reload the table.
    [[RACAble(self.streamList) deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x){
        @strongify(self);
        DDLogInfo(@"Application (%@): Refreshing the stream list.", [self class]);
        DDLogInfo(@"Application (%@): %lu live streams.", [self class], [x count]);

        // Update (or reset) the last updated label.
        self.lastUpdatedTimestamp = [NSDate date];
        [self updateLastUpdatedLabel];

        // Reload the table.
        [_listView reloadDataAnimated:YES];
        self.showingLoading = NO;
    }];

    // If we've fetched streams before, compared the existing list to the newly
    // fetched one to check for any new broadcasts. If so, send those streams
    // to the notification center.
    [[[[[[[[RACAble(self.streamList) deliverOn:[RACScheduler scheduler]] distinctUntilChanged] filter:^BOOL(id value) {
        return (self.preferences.notificationsEnabled == YES && value != nil);
    }] map:^(NSArray *changes) {
        return [NSSet setWithArray:changes];
    }] mapPreviousWithStart:[NSSet set] combine:^id(NSSet *previous, NSSet *current) {
        return [RACTuple tupleWithObjects:previous, current, nil];
    }] map:^(RACTuple *changes) {
        RACTupleUnpack(NSSet *previous, NSSet *current) = changes;
        NSMutableSet *oldStreams = [previous mutableCopy];
        [oldStreams minusSet:current];
        NSMutableSet *newStreams = [current mutableCopy];
        [newStreams minusSet:previous];
        return [RACTuple tupleWithObjects:oldStreams, newStreams, nil];
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(RACTuple *x) {
        RACTupleUnpack(NSSet *oldStreams, NSSet *newStreams) = x;

        if ([oldStreams count] != 0) {
            // Take the `_id` value of each stream in the existing array
            // subtract those that exist in the recently fetched array.
            // Notifications will be sent for the results.
            NSSet *oldStreamIDs = [oldStreams valueForKey:@"_id"];
            NSSet *xorSet = [newStreams filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT _id IN %@", oldStreamIDs]];
            DDLogInfo(@"Notifications: %lu new streams.", (unsigned long)[xorSet count]);
            [self sendNewStreamNotificationToUser:xorSet];
        }
    }];

    // Refresh the stream list at an interval provided by the user.
    [[RACAbleWithStart(self.preferences.streamListRefreshTime) distinctUntilChanged] subscribeNext:^(NSNumber *interval) {
        DDLogInfo(@"Application (%@): Refresh set to %ld seconds.", [self class], [interval integerValue]);
    }];
    [[RACSignal interval:self.preferences.streamListRefreshTime] subscribeNext:^(id x) {
        @strongify(self);
        DDLogVerbose(@"Application (%@): Triggering timed refresh.", [self class]);
        self.client = [TwitchAPIClient sharedClient];
        self.showingLoading = YES;
    }];

    // Monitor the data source array and show an empty view if it's... empty.
    [RACAble(self.streamList) subscribeNext:^(NSArray *streamList) {
        @strongify(self);
        if ((streamList == nil) || ([streamList count] == 0)) { self.showingEmpty = YES; }
        else { self.showingEmpty = NO; }
    }];
}

- (void)updateLastUpdatedLabel
{
    SORelativeDateTransformer *relativeDateTransformer = [[SORelativeDateTransformer alloc] init];
    NSString *relativeDate = [relativeDateTransformer transformedValue:self.lastUpdatedTimestamp];
    NSString *relativeStringValue = [NSString stringWithFormat:@"Updated %@", relativeDate];
    [self.windowController.lastUpdatedLabel setStringValue:relativeStringValue];
}

#pragma mark - NSUserNotificationCenter Methods

- (void)sendNewStreamNotificationToUser:(NSSet *)newSet
{
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (Stream *stream in newSet) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:[NSString stringWithFormat:@"%@ is now live!", stream.channel.displayName]];
        [notification setSubtitle:[NSString stringWithFormat:@"%@", stream.game]];
        [notification setInformativeText:stream.channel.status];
        [notification setSoundName:NSUserNotificationDefaultSoundName];

        NSURL *streamURL = stream.channel.url;
        if (self.preferences.streamPopupEnabled) { streamURL = [streamURL URLByAppendingPathComponent:@"popout"]; }
        [notification setUserInfo:@{ @"URL": [streamURL absoluteString] }];

        // Beam it up, Scotty!
        [center deliverNotification:notification];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if ([notification activationType] == NSUserNotificationActivationTypeContentsClicked) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[notification userInfo][@"URL"]]];
    }
}

#pragma mark - JAListView Methods

- (void)listView:(JAListView *)listView willSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        return;
    }
}

- (void)listView:(JAListView *)listView didSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        return;
    }
}

- (void)listView:(JAListView *)listView didDeselectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        return;
    }
}

#pragma mark - JAListViewDataSource Methods

- (JAListViewItem *)listView:(JAListView *)listView viewAtIndex:(NSUInteger)index
{
    Stream *stream = (self.streamList)[index];
    StreamListViewItem *item = [StreamListViewItem initItem];
    
    item.object = stream;
    [item setNeedsDisplay:YES];
    return item;
}

- (NSUInteger)numberOfItemsInListView:(JAListView *)listView
{
    if (self.streamList != nil) {
        return [self.streamList count];
    }
    return 0;
}

@end
