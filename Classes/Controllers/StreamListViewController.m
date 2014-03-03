//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Butter/BTRActivityIndicator.h>

#import "HexColor.h"
#import "JASectionedListView.h"
#import "JLNFadingScrollView.h"
#import "LoadingView.h"
#import "LoginRequiredView.h"
#import "MainWindowController.h"
#import "NSView+Animations.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
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
@property (nonatomic, strong) MainWindowController *windowController;

@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;
@property (nonatomic, strong) Preferences *preferences;

@property (nonatomic, assign) BOOL loggedIn;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL showingError;
@property (nonatomic, assign) BOOL showingEmpty;
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
    // ...
    _refreshButton.rac_command = self.viewModel.refreshCommand;
    [self.viewModel.refreshCommand.executionSignals subscribeNext:^(id x) {}];

    // Bind the status item's title to the number of active -authenticated-
    // streams, as long as that array exists, and the user wants the count.
    RACSignal *authenticatedStreams = RACObserve(self, viewModel.authenticatedStreams);
    RACSignal *streamCountEnabled = RACObserve(self, preferences.streamCountEnabled);

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
        combineLatest:@[
            RACObserve(self, viewModel.authenticatedStreams),
            RACObserve(self, viewModel.featuredStreams)]]
        subscribeNext:^(id x) {
            @strongify(self);
            [self reloadData]; }
        error:^(NSError *error) {
            @strongify(self);
            DDLogError(@"Application (%@): (Error) %@", [self class], error);
        }];

    // Observe our authenticated stream list (ignoring nil values). Once that
    // value changes, return the stream list so we may further process it.
    RACSignal *notificationsEnabled = [[RACSignal
        combineLatest:@[[authenticatedStreams ignore:nil], RACObserve(self, preferences.notificationsEnabled)]
        reduce:^id(NSArray *streams, NSNumber *notificationsEnabled) {
            DDLogInfo(@"Application (%@): We will now be sending notifications.", [self class]);
            return streams;
        }] distinctUntilChanged];

    // Process the changes after -notificationsEnabled has been tripped (except
    // the first time). Compare the previous array of streams to the new array
    // and return the changes.
    RACSignal *notificationChanges = [[[[notificationsEnabled
        map:^id(NSArray *newStreams) {
            return newStreams; }]
        combinePreviousWithStart:[NSArray array] reduce:^id(id previous, id current) {
            DDLogVerbose(@"Application (%@): Previous stream list = [%@], Current stream list = [%@]", [self class], previous, current);
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
            NSLog(@"Notifications: Array of streams to be pushed = [%@]", array);
            [self sendNewStreamNotificationToUser:array];
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
    [_listView reloadDataAnimated:YES];
    for (StreamListItemView *item in selectedViews) {
        [_listView selectView:item];
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

        DDLogInfo(@"Application (%@): Requested %@'s stream - %@", [self class], item.viewModel.displayName, item.viewModel.hlsURL);
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
