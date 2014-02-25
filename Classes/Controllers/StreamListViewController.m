//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

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
#import "StatusItemView.h"
#import "Stream.h"
#import "StreamViewModel.h"
#import "StreamViewerViewController.h"
#import "StreamListSectionView.h"
#import "StreamListViewModel.h"
#import "StreamListViewItem.h"
#import "MainWindowController.h"

#import "StreamListViewController.h"

enum {
    FeaturedStreams = 0,
    AuthenticatedStreams
};

@interface StreamListViewController () {
    IBOutlet JASectionedListView *_listView;
    IBOutlet JLNFadingScrollView *_scrollView;
    IBOutlet NSButton *_refreshButton;
}

@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSView *loginView;
@property (nonatomic, strong) StatusItemView *statusItem;
@property (nonatomic, strong) RACCommand *refreshCommand;
@property (nonatomic, strong) MainWindowController *windowController;

@property (nonatomic, strong) NSArray *authenticatedStreamList;
@property (nonatomic, strong) NSArray *featuredStreamList;

@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) User *user;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL showingError;
@property (nonatomic, assign) BOOL showingEmpty;
@property (nonatomic, assign) BOOL showingLoading;
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
    self.loadingView = [[LoadingView init] loadingViewWithProgressIndicator];
    self.preferences = [Preferences sharedPreferences];
    self.windowController = [[NSApp delegate] windowController];

    DDLogInfo(@"Application (%@): Stream list loaded.", [self class]);

    [self initializeSignals];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setCanCallDataSourceInParallel:YES];
    [_listView setConditionallyUseLayerBacking:YES];
    [_listView setMargin:NSMakePoint(1, 1)];

    [_scrollView setFadeColor:[NSColor colorWithHexString:@"#000000" alpha:1.0]];
}

- (void)initializeSignals
{

    RACSignal *authenticatedStreams = RACObserve(self, viewModel.authenticatedStreams);
    RACSignal *featuredStreams = RACObserve(self, viewModel.featuredStreams);

    // ...
    _refreshButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        DDLogInfo(@"Application (%@): Request to manually refresh the stream list.", [self class]);
        [_listView reloadDataAnimated:YES];
        return [RACSignal combineLatest:@[authenticatedStreams, featuredStreams]];
    }];


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
                NSLog(@"Application (%@): Status item title updated: %lu.", [self class], [streamList count]);
                return [NSString stringWithFormat:@"%lu", [streamList count]];
            } else {
                DDLogInfo(@"Application (%@): Status item title removed.", [self class]);
                return @"";
            }
        }] distinctUntilChanged];

    [[RACSignal
        combineLatest:@[RACObserve(self, viewModel.authenticatedStreams), RACObserve(self, viewModel.featuredStreams)]]
        subscribeNext:^(id x) {
            [_listView reloadDataAnimated:YES];
        }];
}

//- (void)initializeViewSignals
//{
//    @weakify(self);
//
//    RAC(self, statusItem.title) = [RACSignal combineLatest:@[RACObserve(self, preferences.streamCountEnabled), RACObserve(self, streamList), RACObserve(self, loggedIn)]
//        reduce:^id(NSNumber *countEnabled, NSArray *streamList, NSNumber *loggedIn){
//        if ([countEnabled boolValue] && [streamList count] > 0 && [loggedIn boolValue]) {
//            DDLogInfo(@"Application (%@): Status item title updated. (%lu)", [self class], (unsigned long)[streamList count]);
//            return [NSString stringWithFormat:@"%lu", [streamList count]];
//        } else {
//            DDLogInfo(@"Application (%@): Status item title removed.", [self class]);
//            return @"";
//        }
//    }];
//
//    self.windowController.refreshButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
//        @strongify(self);
//        DDLogInfo(@"Application (%@): Request to manually refresh the stream list.", [self class]);
//        self.client = [TwitchAPIClient sharedClient];
//        self.showingLoading = YES;
//    }];
//
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
//    // Show or hide the loading view.
//    [[[RACObserve(self, showingLoading) distinctUntilChanged]
//      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingLoading) {
//         @strongify(self);
//         BOOL isShowingLoading = [showingLoading boolValue];
//         if (isShowingLoading) {
//             DDLogInfo(@"Application (%@): Showing the loading view.", [self class]);
//             [self.loadingView.progressIndicator startAnimation:self];
//             [self.view addSubview:self.loadingView positioned:NSWindowAbove relativeTo:nil];
//         }
//         else {
//             DDLogInfo(@"Application (%@): Removing the loading view.", [self class]);
//             [self.loadingView removeFromSuperviewAnimated:YES];
//             [self.loadingView.progressIndicator stopAnimation:self];
//             self.loadingView = nil;
//         }
//     }];
//
//    // Show or hide the empty view.
//    [[[RACObserve(self, showingEmpty) distinctUntilChanged]
//      deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *showingEmpty) {
//        @strongify(self);
//        BOOL isShowingEmpty = [showingEmpty boolValue];
//        if (isShowingEmpty && !self.showingError){
//            DDLogInfo(@"Application (%@): Showing the empty view.", [self class]);
//            NSString *title = @"Looks like you've got nothing to watch.";
//            NSString *subTitle = @"Why don't you follow some new streamers?";
//            self.emptyView = [[EmptyErrorView init] emptyViewWithTitle:title subTitle:subTitle];
//            [self.view addSubview:self.emptyView animated:YES];
//        } else {
//            DDLogInfo(@"Application (%@): Removing the empty view.", [self class]);
//            [self.emptyView removeFromSuperviewAnimated:YES];
//            self.emptyView = nil;
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
//            self.showingLoading = NO;
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
//    // We pass a nil user to this controller in order to "reset" the interface.
//    // We'll watch that value, filter then reset the interface.
//    [[RACObserve(self, user) filter:^BOOL(id value) {
//        return (value == nil);
//    }] subscribeNext:^(User *user) {
//        self.client = nil;
//        self.loggedIn = NO;
//        self.streamList = nil;
//    }];
//
//    // Watch for `client` to change or be populated. If so, fetch the stream
//    // list and assign it.
//    [[[RACObserve(self, client) filter:^BOOL(id value) {
//        return (value != nil);
//    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
//        @strongify(self);
//        self.showingLoading = YES;
//        [[[self.client fetchStreamList]
//          deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *streamList) {
//            DDLogInfo(@"Application (%@): Fetching the stream list.", [self class]);
//            @strongify(self);
//            self.streamList = streamList;
//            self.showingError = NO;
//        } error:^(NSError *error) {
//            @strongify(self);
//            DDLogError(@"Application (%@): (Error) %@", [self class], error);
//            self.showingErrorMessage = [self formatError:[error localizedDescription]];
//            self.showingError = YES;
//        }];
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
//        self.showingLoading = NO;
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
//
//    // Refresh the stream list at an interval provided by the user.
//    [[RACObserve(self, preferences.streamListRefreshTime) distinctUntilChanged] subscribeNext:^(NSNumber *interval) {
//        DDLogInfo(@"Application (%@): Refresh set to %ld seconds.", [self class], [interval integerValue]);
//    }];
//    
//    // We store the stream list refresh time in minutes, so take
//    // that value and multiply it by 60 for great justice.
//    [[RACSignal interval:[self.preferences.streamListRefreshTime doubleValue] * 60 onScheduler:[RACScheduler scheduler]] subscribeNext:^(id x) {
//        @strongify(self);
//        DDLogVerbose(@"Application (%@): Triggering timed refresh.", [self class]);
//        self.client = [TwitchAPIClient sharedClient];
//        self.showingLoading = YES;
//    }];
//
//    // Monitor the data source array and show an empty view if it's... empty.
//    [RACObserve(self, streamList) subscribeNext:^(NSArray *streamList) {
//        @strongify(self);
//        if ((streamList == nil) || ([streamList count] == 0)) { self.showingEmpty = YES; }
//        else { self.showingEmpty = NO; }
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
    if (listView != _listView) { return; }

    StreamListViewItem *item = (StreamListViewItem *)view;
    [self.windowController.viewerController setSelectedStream:item.object];
    DDLogInfo(@"Application (%@): Requested %@'s stream - %@", [self class], item.object.channel.displayName, item.object.hlsURL);
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

- (JAListViewItem *)listView:(JAListView *)listView viewForSection:(NSUInteger)section index:(NSUInteger)index
{
    StreamListViewItem *item = [StreamListViewItem initItem];

    switch (section) {
        case 0:
            item.object = [self.viewModel.authenticatedStreams objectAtIndex:index];
            break;
        case 1:
            item.object = [self.viewModel.featuredStreams objectAtIndex:index];
            break;
        default:
            break;
    }

    [item setNeedsDisplay:YES];
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
