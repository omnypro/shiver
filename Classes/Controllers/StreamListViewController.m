//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Butter/BTRActivityIndicator.h>

#import "TwitchAPIClient.h"
#import "Channel.h"
#import "EmptyErrorView.h"
#import "HexColor.h"
#import "NSView+Animations.h"
#import "JASectionedListView.h"
#import "LoadingView.h"
#import "LoginRequiredView.h"
#import "JLNFadingScrollView.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "Stream.h"
#import "StreamViewModel.h"
#import "StreamViewerViewController.h"
#import "StreamListSectionView.h"
#import "StreamListViewModel.h"
#import "StreamListItemView.h"
#import "MainWindowController.h"

#import "StreamListViewController.h"

enum {
    FeaturedStreams = 0,
    AuthenticatedStreams
};

@interface StreamListViewController () {
    IBOutlet BTRActivityIndicator *_activityIndicator;
    IBOutlet JASectionedListView *_listView;
    IBOutlet JLNFadingScrollView *_scrollView;
    IBOutlet LoadingView *_loadingView;
    IBOutlet NSButton *_refreshButton;
}

@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSView *loginView;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) RACCommand *refreshCommand;
@property (nonatomic, strong) MainWindowController *windowController;

@property (nonatomic, strong) NSArray *authenticatedStreamList;
@property (nonatomic, strong) NSArray *featuredStreamList;

@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) User *user;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL showingError;
@property (nonatomic, assign) BOOL showingEmpty;
@property (nonatomic, strong) NSString *showingErrorMessage;

- (void)sendNewStreamNotificationToUser:(NSSet *)newSet;
@end

@implementation StreamListViewController

@dynamic viewModel;

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    self.loginView = [LoginRequiredView init];
    self.statusItem = [[NSApp delegate] statusItem];
    self.preferences = [Preferences sharedPreferences];
    self.windowController = [[NSApp delegate] windowController];

    DDLogInfo(@"Application (%@): Stream list loaded.", [self class]);

    [self initializeSignals];
    [self initializeLifecycleSignals];

    [_activityIndicator setProgressShapeColor:[NSColor whiteColor]];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setCanCallDataSourceInParallel:YES];
    [_listView setConditionallyUseLayerBacking:YES];
    [_listView setPadding:JAEdgeInsetsMake(-5, 0, 5, 0)];

    [_scrollView setFadeColor:[NSColor colorWithHexString:@"#000000" alpha:0.5]];
}

- (void)initializeSignals
{
    RACSignal *authenticatedStreams = RACObserve(self, viewModel.authenticatedStreams);
    RACSignal *featuredStreams = RACObserve(self, viewModel.featuredStreams);

    // ...
    _refreshButton.rac_command = self.viewModel.refreshCommand;
    [self.viewModel.refreshCommand.executionSignals subscribeNext:^(id x) {}];

    // Bind the status item's title to the number of active -authenticated-
    // streams, as long as that array exists, and the user wants the count.
    RACSignal *streamCountEnabled = RACObserve(self, preferences.streamCountEnabled);

    RAC(self, authenticatedStreamList) = authenticatedStreams;
    RAC(self, featuredStreamList) = featuredStreams;

    @weakify(self);

    RAC(self, statusItem.title) = [[RACSignal
        combineLatest:@[streamCountEnabled, authenticatedStreams]
        reduce:^id(NSNumber *streamCountEnabled, NSArray *streamList) {
            @strongify(self);
            if ([streamCountEnabled boolValue] && [streamList count] > 0) {
                DDLogInfo(@"Application (%@): Status item title updated: %lu.", [self class], [streamList count]);
                return [NSString stringWithFormat:@"%lu", [streamList count]];
            } else {
                DDLogInfo(@"Application (%@): Status item title removed.", [self class]);
                return @"";
            }
        }] distinctUntilChanged];

    [[RACSignal
        combineLatest:@[RACObserve(self, viewModel.authenticatedStreams), RACObserve(self, viewModel.featuredStreams)]]
        subscribeNext:^(id x) {
            @strongify(self);        
            [self reloadData];
        } error:^(NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];
}

- (void)initializeLifecycleSignals
{
    @weakify(self);

    // Show or hide the loading view.
    [RACObserve(self, viewModel.isLoading)
        subscribeNext:^(NSNumber *loading) {
            @strongify(self);
            BOOL isLoading = [loading boolValue];
            if (isLoading) {
                DDLogInfo(@"Application (%@): Showing the loading view.", [self class]);
                [self.view addSubview:_loadingView];
                [_activityIndicator startAnimating];
            } else {
                DDLogInfo(@"Application (%@): Removing the loading view.", [self class]);
                [_loadingView removeFromSuperview];
                [_activityIndicator stopAnimating];
            }
        }];

    // Refresh the stream list at an interval provided by the user.
    [[RACObserve(self, preferences.streamListRefreshTime) distinctUntilChanged]
        subscribeNext:^(NSNumber *interval) {
            DDLogInfo(@"Application (%@): Refresh set to %ld seconds.", [self class], [interval integerValue]);
        }];

    // We store the stream list refresh time in minutes, so take
    // that value and multiply it by 60 for great justice.
    [[RACSignal interval:[self.preferences.streamListRefreshTime doubleValue] * 60
        onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            @strongify(self);
            DDLogVerbose(@"Application (%@): Triggering timed refresh.", [self class]);
            [self.viewModel.refreshCommand execute:nil];
        }];
}

//- (void)initializeViewSignals
//{
//    // Watch the stream list for changes and enable or disable UI elements
//    // based on those values.
//    [[RACObserve(self, streamList) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *array) {
//        @strongify(self);
//        if ([array count] > 0) {
//            [self.windowController.refreshButton setEnabled:YES];
//
//            // Update the string based on the number of streams that are live.
//            NSString *singularCount = [NSString stringWithFormat:@"%lu live stream", [array count]];
//            NSString *pluralCount = [NSString stringWithFormat:@"%lu live streams", [array count]];
//            if ([array count] == 1) { [self.windowController.statusLabel setStringValue:singularCount]; }
//            else if ([array count] > 1) { [self.windowController.statusLabel setStringValue:pluralCount]; }
//            else { [self.windowController.statusLabel setStringValue:@"No live streams"]; }
//        }
//        else {
//            [self.windowController.statusLabel setStringValue:@"No live streams"];
//        }
//    }];
//
//    // Updated the lastUpdated label every 30 seconds.
//    NSTimeInterval lastUpdatedInterval = 30.0;
//    [[[[RACObserve(self, streamList) filter:^BOOL(NSArray *array) {
//        return (array != nil);
//    }] map:^id(id value) {
//        return [RACSignal interval:lastUpdatedInterval onScheduler:[RACScheduler scheduler]];
//    }] switchToLatest] subscribeNext:^(NSArray *array) {
//        @strongify(self);
//        if (array != nil) {
//            DDLogVerbose(@"Application (%@): Updating the last updated label (on interval).", [self class]);
//            [self updateLastUpdatedLabel];
//        }
//    }];
//
//    // Show or hide the error view.
//    [[[RACObserve(self, showingError) distinctUntilChanged]
//      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingError) {
//        @strongify(self);
//        BOOL isShowingError = [showingError boolValue];
//        if (isShowingError) {
//            // Don't show the empty or loading views if there's an error.
//            self.showingEmpty = NO;
//            self.isLoading = NO;
//            NSString *title = @"Whoops! Something went wrong.";
//            NSString *message = self.showingErrorMessage ? self.showingErrorMessage : @"Undefined error.";
//            DDLogError(@"Application (%@): Showing the error view with message, \"%@\"", [self class], message);
//            self.errorView = [[EmptyErrorView init] errorViewWithTitle:title subTitle:message];
//            [self.view addSubview:self.errorView animated:YES];
//        }
//        else {
//            DDLogInfo(@"Application (%@): Removing the error view.", [self class]);
//            [self.errorView removeFromSuperviewAnimated:YES];
//            self.errorView = nil;
//            self.showingErrorMessage = nil;
//        }
//    }];
//
//    // Show or hide the login view.
//    [[[RACObserve(self, loggedIn) distinctUntilChanged]
//      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingLogin) {
//        @strongify(self);
//        BOOL isShowingLogin = [showingLogin boolValue];
//        if (!isShowingLogin) {
//            DDLogInfo(@"Application (%@): Showing the login view.", [self class]);
//            // Don't show any of the other views if we're going to show login.
//            self.errorView = NO;
//            self.loadingView = NO;
//            [self.view addSubview:self.loginView animated:YES];
//        }
//        else {
//            DDLogInfo(@"Application (%@): Removing the login view.", [self class]);
//            [self.loginView removeFromSuperviewAnimated:YES];
//        }
//    }];
//}

//- (void)initializeDataSignals
//{
//    @weakify(self);
//
//    // Watch for `user` to change or be populated. If it is, start the process
//    // off by spawning the API client.
//    [[RACObserve(self, user) filter:^BOOL(id value) {
//        return (value != nil);
//    }] subscribeNext:^(User *user) {
//        DDLogInfo(@"Application (%@): Loading client for %@.", [self class], user.name);
//        @strongify(self);
//        self.client = [TwitchAPIClient sharedClient];
//        self.loggedIn = YES;
//        [self.windowController.statusLabel setStringValue:@"Loading..."];
//    }];
//
//    // When the stream list gets changed, reload the table.
//    [[RACObserve(self, streamList) deliverOn:[RACScheduler mainThreadScheduler]]
//      subscribeNext:^(id x){
//        @strongify(self);
//        DDLogInfo(@"Application (%@): Asked to refresh the stream list.", [self class]);
//        
//        DDLogInfo(@"Application (%@): Refreshing the stream list.", [self class]);
//        DDLogInfo(@"Application (%@): %lu live streams.", [self class], [x count]);
//
//        // Update (or reset) the last updated label.
//        self.lastUpdatedTimestamp = [NSDate date];
//        [self updateLastUpdatedLabel];
//
//        // Reload the table.
//        [_listView reloadDataAnimated:YES];
//        self.isLoading = NO;
//
//        // If we don't have a user, don't run this!
//        else { DDLogInfo(@"Application (%@): We don't have a user; not refreshing the list.", [self class]); }
//    }];
//
//    // If we've fetched streams before, compared the existing list to the newly
//    // fetched one to check for any new broadcasts. If so, send those streams
//    // to the notification center.
//    [[[[[[[[RACObserve(self, streamList) deliverOn:[RACScheduler scheduler]] distinctUntilChanged] filter:^BOOL(id value) {
//        return (self.preferences.notificationsEnabled == YES && value != nil);
//    }] map:^(NSArray *changes) {
//        return [NSSet setWithArray:changes];
//    }] combinePreviousWithStart:[NSSet set] reduce:^id(NSSet *previous, NSSet *current) {
//        return [RACTuple tupleWithObjects:previous, current, nil];
//    }] map:^(RACTuple *changes) {
//        RACTupleUnpack(NSSet *previous, NSSet *current) = changes;
//        NSMutableSet *oldStreams = [previous mutableCopy];
//        [oldStreams minusSet:current];
//        NSMutableSet *newStreams = [current mutableCopy];
//        [newStreams minusSet:previous];
//        return [RACTuple tupleWithObjects:oldStreams, newStreams, nil];
//    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(RACTuple *x) {
//        RACTupleUnpack(NSSet *oldStreams, NSSet *newStreams) = x;
//
//        if ([oldStreams count] != 0) {
//            // Take the `_id` value of each stream in the existing array
//            // subtract those that exist in the recently fetched array.
//            // Notifications will be sent for the results.
//            NSSet *oldStreamIDs = [oldStreams valueForKey:@"_id"];
//            NSSet *xorSet = [newStreams filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT _id IN %@", oldStreamIDs]];
//            // With the way we instantiate our xorSet, there's a
//            // possibility that duplicates can pass through.
//            // Throwing the set into another set could be a way
//            // to fix the problem of duplicates.
//            NSSet *uniqueSet = [NSSet setWithSet:xorSet];
//            DDLogInfo(@"Notifications: %lu new streams.", (unsigned long)[uniqueSet count]);
//            [self sendNewStreamNotificationToUser:uniqueSet];
//        }
//    }];
//}

- (NSString *)formatError:(NSString *)errorString
{
    NSString *string = errorString;
    if ([string rangeOfString:@"401"].location != NSNotFound) { string = @"Twitch says we're unauthorized. Try logging in again."; }
    if ([string rangeOfString:@"408"].location != NSNotFound) { string = @"Our request for streams timed out. Try refreshing."; }
    if ([string rangeOfString:@"500"].location != NSNotFound) { string = @"Twitch's servers are erroring out. Try refreshing."; }
    if ([string rangeOfString:@"502"].location != NSNotFound) { string = @"Twitch isn't listening to us right now. Try refreshing."; }
    if ([string rangeOfString:@"503"].location != NSNotFound) { string = @"Twitch is down at the moment. Come back later."; }
    return string;
}

- (void)reloadData {
    NSSet *selectedViews = [NSSet setWithArray:_listView.selectedViews];
    [_listView reloadData];
    for (StreamListItemView *item in selectedViews) {
        [_listView selectView:item];
    }
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

#pragma mark - JASectionedListView Methods

- (void)listView:(JAListView *)listView willSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        if ([(JASectionedListView *)listView isViewSectionHeaderView:view]) {
            return;
        }

        StreamListItemView *item = (StreamListItemView *)view;
        [item setSelected:YES];

        DDLogInfo(@"Application (%@): JAListView will select -- %@", [self class], item);
    }

    [_listView reloadLayoutAnimated:NO];
}

- (void)listView:(JAListView *)listView didSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        if ([(JASectionedListView *)listView isViewSectionHeaderView:view]) {
            return;
        }

        StreamListItemView *item = (StreamListItemView *)view;
        [item setSelected:YES];

        if (self.windowController.viewerController.stream != item.viewModel) {
            [self.windowController.viewerController setStream:item.viewModel];
        }

        DDLogInfo(@"Application (%@): Requested %@'s stream - %@", [self class], item.viewModel.channel.displayName, item.viewModel.hlsURL);
        DDLogInfo(@"Application (%@): JAListView did select -- %@", [self class], item.viewModel);
    }

    [_listView reloadLayoutAnimated:NO];
}

- (void)listView:(JAListView *)listView didDeselectView:(JAListViewItem *)view
{
    StreamListItemView *item = (StreamListItemView *)view;
    DDLogInfo(@"Application (%@): JAListView did deselect -- %@", [self class], item);
    [listView reloadLayoutAnimated:NO];
}

#pragma mark - JAListViewDataSource Methods

- (JAListViewItem *)listView:(JAListView *)listView viewForSection:(NSUInteger)section index:(NSUInteger)index
{
    StreamListItemView *item = nil;

    switch (section) {
        case 0:
            item = [StreamListItemView initItemStream:[self.viewModel.authenticatedStreams objectAtIndex:index]];
            break;
        case 1:
            item = [StreamListItemView initItemStream:[self.viewModel.featuredStreams objectAtIndex:index]];
            break;
        default:
            break;
    }

    return item;
}

- (JAListViewItem *)listView:(JAListView *)listView sectionHeaderViewForSection:(NSUInteger)section
{
    StreamListSectionView *item = [StreamListSectionView initItem];

    switch (section) {
        case 0:
            [item.title setStringValue:@"Your Follows"];
            break;
        case 1:
            [item.title setStringValue:@"Featured Streams"];
            break;
    }

    return item;
}

- (NSUInteger)numberOfSectionsInListView:(JASectionedListView *)listView
{
    return 2;
}

-(NSUInteger)listView:(JASectionedListView *)listView numberOfViewsInSection:(NSUInteger)section
{
    NSUInteger count = 0;

    switch (section) {
        case 0:
            count = [self.viewModel.authenticatedStreams count];
            break;
        case 1:
            count = [self.viewModel.featuredStreams count];
            break;
        default:
            break;
    }

    return count;
}

@end
