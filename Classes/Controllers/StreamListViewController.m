//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Butter/BTRActivityIndicator.h>

#import "ApplicationController.h"
#import "AccountManager.h"
#import "ErrorView.h"
#import "HexColor.h"
#import "JAObjectListView.h"
#import "JLNFadingScrollView.h"
#import "LoadingView.h"
#import "LoginRequiredView.h"
#import "MainWindowController.h"
#import "NSView+Animations.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "StreamListEmptyItemView.h"
#import "StreamListItemView.h"
#import "StreamListSectionView.h"
#import "StreamListViewModel.h"
#import "StreamViewerViewController.h"
#import "StreamViewModel.h"
#import "YOLO.h"

#import "StreamListViewController.h"

enum {
    FeaturedStreams = 0,
    AuthenticatedStreams
};

@interface StreamListViewController () {
    IBOutlet BTRActivityIndicator *_activityIndicator;
    IBOutlet ErrorView *_errorView;
    IBOutlet JAObjectListView *_listView;
    IBOutlet JLNFadingScrollView *_scrollView;
    IBOutlet LoadingView *_loadingView;
    IBOutlet NSButton *_refreshButton;
}

@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) LoadingView *loadingView;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) MainWindowController *windowController;
@property (nonatomic, strong) StreamViewerViewController *viewerViewController;

@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) Preferences *preferences;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL showingError;
@property (nonatomic, assign) BOOL showingEmpty;

@property (nonatomic, strong) NSString *emptyMessage;
@property (nonatomic, strong) NSString *showingErrorMessage;

- (void)sendNewStreamNotificationToUser:(NSArray *)streams;

@end

@implementation StreamListViewController

@dynamic viewModel;

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    self.preferences = [Preferences sharedPreferences];
    self.windowController = [[NSApp delegate] windowController];

    DDLogInfo(@"Stream list loaded.");

    [self initializeListViewHeaders];
    [self initializeSignals];
    [self initializeLifecycleSignals];

    [_activityIndicator setProgressShapeColor:[NSColor whiteColor]];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setConditionallyUseLayerBacking:YES];
    [_listView setPadding:JAEdgeInsetsMake(-5, 0, 5, 0)];

    [_scrollView setFadeColor:[NSColor colorWithHexString:@"#000000" alpha:0.5]];
}

- (void)initializeListViewHeaders
{
    StreamListSectionView *authenticatedHeaderItem = [StreamListSectionView initItem];
    [authenticatedHeaderItem.title setStringValue:@"Your Follows"];
    [_listView addListViewItem:authenticatedHeaderItem forHeaderForSection:0];

    StreamListSectionView *featuredHeaderItem = [StreamListSectionView initItem];
    [featuredHeaderItem.title setStringValue:@"Featured Streams"];
    [_listView addListViewItem:featuredHeaderItem forHeaderForSection:1];
}

- (void)initializeSignals
{
    // ...
    _refreshButton.rac_command = self.viewModel.refreshCommand;
    [self.viewModel.refreshCommand.executionSignals subscribeNext:^(id x) {}];

    // Bind our status item to the application delegate's status item. If
    // the user chooses to toggle icon visibility, there's a chance that
    // statusItem is deallocated, meaning that we can no longer override
    // the title.
    ApplicationController *delegate = [ApplicationController sharedInstance];
    RAC(self, statusItem) = RACObserve(delegate, statusItem);

    // Bind the status item's title to the number of active -authenticated-
    // streams, as long as that array exists, and the user wants the count.
    RACSignal *authenticatedStreams = RACObserve(self, viewModel.authenticatedStreams);
    RACSignal *streamCountEnabled = RACObserve(self, preferences.streamCountEnabled);

    @weakify(self);

    RAC(self, statusItem.title) = [[RACSignal
        combineLatest:@[streamCountEnabled, authenticatedStreams, RACObserve(self, preferences.iconVisibility)]
        reduce:^id(NSNumber *streamCountEnabled, NSArray *streamList, NSNumber *iconVisibility) {
            if ([streamCountEnabled boolValue] && [streamList count] > 0) {
                DDLogInfo(@"Status item title updated: %lu.", [streamList count]);
                return [NSString stringWithFormat:@"%lu", [streamList count]];
            } else {
                DDLogInfo(@"Status item title removed.");
                return @"";
            }
        }] deliverOn:[RACScheduler mainThreadScheduler]];

    [[RACSignal
        combineLatest:@[
            RACObserve(self, viewModel.authenticatedStreams),
            RACObserve(self, viewModel.featuredStreams)]]
        subscribeNext:^(id x) {
            @strongify(self);
            [self reloadData]; }
        error:^(NSError *error) {
            DDLogError(@"%@", error);
        }];

    // ...
    [[[RACObserve(self, viewModel.featuredStreams) skip:1]
        combinePreviousWithStart:@[] reduce:^id(NSArray *previous, NSArray *current) {
            DDLogVerbose(@"Previous featured stream list = [%@], Current featured stream list = [%@]", previous, current);
            return [RACTuple tupleWithObjects:current, previous, nil]; }]
        subscribeNext:^(RACTuple *tuple) {
            if (![tuple[0] isEqualToArray:tuple[1]]) {
                [self modifyListViewWithObjects:tuple inSection:1];
                DDLogInfo(@"Adding %lu streams to the featured list.", [tuple[0] count]);
                DDLogInfo(@"Removing %lu streams from the featured list.", [tuple[1] count]);
            } else {
                DDLogInfo(@"Taking no action on the featured list.");
            }
        }];

    // ...
    [[[RACObserve(self, viewModel.authenticatedStreams) skip:1]
        combinePreviousWithStart:@[] reduce:^id(NSArray *previous, NSArray *current) {
            if (![current count]) { current = @[]; }
            NSArray *toAdd = current.without(![previous count] ? @[] : previous);
            if (![previous count]) { previous = @[]; }
            NSArray *toRemove = previous.without(![current count] ? @[] : current);

            DDLogVerbose(@"Previous authenticated stream list = [%@], Current authenticated stream list = [%@]", previous, current);
            return [RACTuple tupleWithObjects:toAdd, toRemove, nil]; }]
        subscribeNext:^(RACTuple *tuple) {
            if (![tuple[0] isEqualToArray:tuple[1]]) {
                [self modifyListViewWithObjects:tuple inSection:0];
                DDLogInfo(@"Adding %lu streams to the authenticated list.", [tuple[0] count]);
                DDLogInfo(@"Removing %lu streams from the authenticated list.", [tuple[1] count]);
            } else if (![self.viewModel.authenticatedStreams count]) {
                DDLogInfo(@"There are no streams, adding empty view.");
                [self displayEmptyListItem];
            } else {
                DDLogInfo(@"Taking no action on the authenticated list.");
            }
        }];

    // Observe our authenticated stream list (ignoring nil values). Once that
    // value changes, return the stream list so we may further process it.
    RACSignal *notificationsEnabled = [[RACSignal
        combineLatest:@[[authenticatedStreams ignore:nil], RACObserve(self, preferences.notificationsEnabled)]
        reduce:^id(NSArray *streams, NSNumber *notificationsEnabled) {
            DDLogInfo(@"We will now be sending notifications.");
            return streams;
        }] distinctUntilChanged];

    // Process the changes after -notificationsEnabled has been tripped (except
    // the first time). Compare the previous array of streams to the new array
    // and return the changes.
    RACSignal *notificationChanges = [[[[notificationsEnabled
        map:^id(NSArray *newStreams) {
            return newStreams; }]
        combinePreviousWithStart:[NSArray array] reduce:^id(id previous, id current) {
            DDLogVerbose(@"Previous stream list = [%@], Current stream list = [%@]", previous, current);
            return [RACTuple tupleWithObjects:previous, current, nil]; }]
        map:^id(RACTuple *tuple) {
            RACTupleUnpack(NSArray *previous, NSArray *current) = tuple;
            return current.without(previous);
        }] skip:1];

    // Subscribe to -notificationChanges and send a notification for every
    // new stream that we have.
    [[[notificationChanges deliverOn:[RACScheduler mainThreadScheduler]]
        filter:^BOOL(NSArray *array) {
            DDLogInfo(@"Notifications: %lu new streams.", [array count]);
            return ([array count] > 0); }]
        subscribeNext:^(NSArray *array) {
            DDLogInfo(@"Notifications: Array of streams to be pushed = [%@]", array);
            [self sendNewStreamNotificationToUser:array];
        }];
}

- (void)initializeLifecycleSignals
{
    @weakify(self);

    // Show or hide the loading view.
    [[RACObserve(self, viewModel.isLoading) distinctUntilChanged]
        subscribeNext:^(NSNumber *loading) {
            @strongify(self);
            BOOL isLoading = [loading boolValue];
            if (isLoading) {
                DDLogWarn(@"Showing the loading view.");
                [self.view addSubview:_loadingView];
                [_activityIndicator startAnimating];
            } else {
                DDLogWarn(@"Removing the loading view.");
                [_loadingView removeFromSuperview];
                [_activityIndicator stopAnimating];
            }
        }];

    // Refresh the stream list at an interval provided by the user.
    [[RACObserve(self, preferences.streamListRefreshTime) distinctUntilChanged]
        subscribeNext:^(NSNumber *interval) {
            DDLogInfo(@"Refresh set to %ld seconds.", [interval integerValue]);
        }];

    // We store the stream list refresh time in minutes, so take
    // that value and multiply it by 60 for great justice.
    [[RACSignal interval:[self.preferences.streamListRefreshTime doubleValue] * 60
        onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            @strongify(self);
            DDLogVerbose(@"Triggering timed refresh.");
            [self.viewModel.refreshCommand execute:nil];
        }];

    RACSignal *readySignal = [[AccountManager sharedManager] readySignal];
    RAC(self, emptyMessage, @"") = [[readySignal
        map:^id(NSNumber *isReady) {
            return isReady ? @"Nobody's streaming. :(" : @"Connect to see your follows.";
        }] deliverOn:[RACScheduler mainThreadScheduler]];

    // Watch -readySignal: to see if it becomes nil. If so, unset the
    // viewerController's stream so the interface can be reverted appropriately.
    [[readySignal ignore:@YES]
        subscribeNext:^(id x) {
            DDLogInfo(@"Cannot detect a credential.");
            [self.windowController.viewerController setStream:nil];
            [self clearListViewSelection];
        }];

    // Observe the stream to see if it becomes nil, if so, clear any selection
    // in the list view so we don't inadvertently reload the stream on refresh.
    [[[[RACObserve(self, windowController.viewerController.stream) distinctUntilChanged]
        deliverOn:[RACScheduler mainThreadScheduler]]
        filter:^BOOL(id value) { return (value == nil); }]
        subscribeNext:^(id x) { [self clearListViewSelection]; }];

    // ...
    [[[[RACObserve(self, viewModel.hasError) skip:1] distinctUntilChanged]
        deliverOn:[RACScheduler mainThreadScheduler]]
        subscribeNext:^(NSNumber *hasError) {
            if ([hasError boolValue]) {
                DDLogWarn(@"Showing the error view.");
                [self.view addSubview:_errorView];
            } else {
                DDLogWarn(@"Removing the error view.");
                [_errorView removeFromSuperview];
            }
        }];
}

//- (void)initializeViewSignals
//{
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
//            DDLogError(@"Showing the error view with message, \"%@\"", message);
//            self.errorView = [[EmptyErrorView init] errorViewWithTitle:title subTitle:message];
//            [self.view addSubview:self.errorView animated:YES];
//        }
//        else {
//            DDLogInfo(@"Removing the error view.");
//            [self.errorView removeFromSuperviewAnimated:YES];
//            self.errorView = nil;
//            self.showingErrorMessage = nil;
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

- (void)modifyListViewWithObjects:(RACTuple *)tuple inSection:(NSUInteger)section
{
    RACTupleUnpack(NSArray *toAdd, NSArray *toRemove) = tuple;

    if (section == 0 && [[_listView viewInSection:0 atIndex:0] isKindOfClass:[StreamListEmptyItemView class]]) {
        [_listView removeListViewItemInSection:0 atIndex:0];
    }

    [[[[toRemove.rac_sequence
        map:^id(StreamViewModel *value) {
            [_listView removeListViewItemForObject:value];
            return [RACSignal return:value];
        }] eagerSequence] signal] deliverOn:[RACScheduler mainThreadScheduler]];
    [[[[[toAdd.rac_sequence
        filter:^BOOL(StreamViewModel *value) {
             return (value.isFollowed == NO); }]
        map:^id(StreamViewModel *value) {
            StreamListItemView *item = [StreamListItemView initItemStream:value];
            [_listView addListViewItem:item inSection:section];
            return [RACSignal return:value];
        }] eagerSequence] signal] deliverOn:[RACScheduler mainThreadScheduler]];
}

- (void)displayEmptyListItem
{
    if (![[_listView viewInSection:0 atIndex:0] isKindOfClass:[StreamListEmptyItemView class]]) {
        StreamListEmptyItemView *item = [StreamListEmptyItemView initItem];
        item.emptyLabel.stringValue = self.emptyMessage;
        [_listView addListViewItem:item inSection:0 atIndex:0];
    }
}

- (void)clearListViewSelection
{
    NSSet *selectedViews = [NSSet setWithArray:_listView.selectedViews];
    for (StreamListItemView *item in selectedViews) {
        [_listView deselectView:item];

        JAObjectListViewItem *selectedItem = [_listView viewItemForObject:item.object];
        [selectedItem setSelected:NO];
    }

    [_listView setNeedsDisplay:YES];
}

- (void)reloadData
{
    NSSet *selectedViews = [NSSet setWithArray:_listView.selectedViews];
    [_listView reloadDataAnimated:YES];
    for (StreamListItemView *item in selectedViews) {
        [_listView selectView:item];

        JAObjectListViewItem *selectedItem = [_listView viewItemForObject:item.object];
        [selectedItem setSelected:YES];
    }

    [_listView setNeedsDisplay:YES];
}

#pragma mark - NSUserNotificationCenter Methods

- (void)sendNewStreamNotificationToUser:(NSArray *)streams
{
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (StreamViewModel *stream in streams.uniq) {
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        [notification setTitle:[NSString stringWithFormat:@"%@ is now live!", stream.displayName]];
        [notification setSubtitle:[NSString stringWithFormat:@"%@", stream.game]];
        [notification setInformativeText:stream.status];
        [notification setSoundName:NSUserNotificationDefaultSoundName];
        [notification setUserInfo:@{ @"URL": [stream.url absoluteString] }];

        // Beam it up, Scotty!
        [center deliverNotification:notification];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if ([notification activationType] == NSUserNotificationActivationTypeContentsClicked) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[notification userInfo][@"URL"]]];
    }
}

#pragma mark - JASectionedListView Methods

- (void)listView:(JAListView *)listView willSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        if ([(JASectionedListView *)listView isViewSectionHeaderView:view]) { return; }
        if ([view isKindOfClass:[StreamListEmptyItemView class]]) { return; }

        StreamListItemView *item = (StreamListItemView *)view;
        [item setSelected:YES];

        DDLogInfo(@"JAListView will select -- %@", item);
    }

    [_listView reloadLayoutAnimated:NO];
}

- (void)listView:(JAListView *)listView didSelectView:(JAListViewItem *)view
{
    if (listView == _listView) {
        if ([(JASectionedListView *)listView isViewSectionHeaderView:view]) { return; }
        if ([view isKindOfClass:[StreamListEmptyItemView class]]) { return; }

        StreamListItemView *item = (StreamListItemView *)view;
        [item setSelected:YES];

        if (self.windowController.viewerController.stream != item.viewModel) {
            [self.windowController.viewerController setStream:item.viewModel];
        }

        DDLogInfo(@"Requested %@'s stream - %@", item.viewModel.displayName, item.viewModel.hlsURL);
        DDLogInfo(@"JAListView did select -- %@", item.viewModel);
    }

    [_listView reloadLayoutAnimated:NO];
}

- (void)listView:(JAListView *)listView didDeselectView:(JAListViewItem *)view
{
    StreamListItemView *item = (StreamListItemView *)view;
    DDLogInfo(@"JAListView did deselect -- %@", item);
    [listView reloadLayoutAnimated:NO];
}

@end
