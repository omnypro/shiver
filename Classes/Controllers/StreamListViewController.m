//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Butter/BTRActivityIndicator.h>

#import "AccountManager.h"
#import "ApplicationController.h"
#import "ErrorView.h"
#import "HexColor.h"
#import "JAObjectListView.h"
#import "LoadingView.h"
#import "MainWindowController.h"
#import "NSView+Animations.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "StreamListEmptyItemView.h"
#import "StreamListItemView.h"
#import "StreamListSectionView.h"
#import "StreamListViewModel.h"
#import "StreamMenuItem.h"
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
    IBOutlet JAObjectListView *_listView;
    IBOutlet LoadingView *_loadingView;
    IBOutlet NSButton *_refreshButton;
}

@property (nonatomic, strong) MainWindowController *windowController;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) Preferences *preferences;
@property (nonatomic, strong) StreamViewerViewController *viewerViewController;

@property (nonatomic, strong) NSString *emptyMessage;
@property (nonatomic, strong) NSString *showingErrorMessage;

@property (nonatomic, weak) IBOutlet ErrorView *errorView;

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
    [self initializeMenu];

    [_activityIndicator setProgressShapeColor:[NSColor whiteColor]];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setConditionallyUseLayerBacking:YES];
    [_listView setPadding:JAEdgeInsetsMake(-5, 0, 5, 0)];
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
    _refreshButton.rac_command = self.viewModel.fetchCommand;
    [self.viewModel.fetchCommand execute:nil];

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

    RACSignal *readySignal = [[AccountManager sharedManager] readySignal];
    [readySignal subscribeNext:^(id x) {
        @strongify(self);
        DDLogInfo(@"User status has changed, refresh the list.");
        [self.viewModel.fetchCommand execute:nil];
    }];

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
            if (![current count]) { current = @[]; }
            NSArray *toAdd = current.without(![previous count] ? @[] : previous);
            if (![previous count]) { previous = @[]; }
            NSArray *toRemove = previous.without(![current count] ? @[] : current);

            DDLogVerbose(@"Previous featured stream list = [%@], Current featured stream list = [%@]", previous, current);
            return RACTuplePack(toAdd, toRemove); }]
        subscribeNext:^(RACTuple *tuple) {
            [self modifyListViewWithObjects:tuple inSection:1];
            DDLogInfo(@"Adding %lu streams to the featured list.", [tuple[0] count]);
            DDLogInfo(@"Removing %lu streams from the featured list.", [tuple[1] count]);
        }];

    // ...
    [[[RACObserve(self, viewModel.authenticatedStreams) skip:1]
        combinePreviousWithStart:@[] reduce:^id(NSArray *previous, NSArray *current) {
            if (![current count]) { current = @[]; }
            NSArray *toAdd = current.without(![previous count] ? @[] : previous);
            if (![previous count]) { previous = @[]; }
            NSArray *toRemove = previous.without(![current count] ? @[] : current);

            DDLogVerbose(@"Previous authenticated stream list = [%@], Current authenticated stream list = [%@]", previous, current);
            return RACTuplePack(toAdd, toRemove); }]
        subscribeNext:^(RACTuple *tuple) {
            [self modifyListViewWithObjects:tuple inSection:0];
            DDLogInfo(@"Adding %lu streams to the authenticated list.", [tuple[0] count]);
            DDLogInfo(@"Removing %lu streams from the authenticated list.", [tuple[1] count]);

            if (![self.viewModel.authenticatedStreams count]) {
                DDLogInfo(@"There are no streams, adding empty view.");
                [self displayEmptyListItem];
            }
        }];

    // Observe our authenticated stream list (ignoring nil values). Once that
    // value changes, return the stream list so we may further process it.
    RACSignal *notificationsEnabled = [[RACSignal
        combineLatest:@[
            [authenticatedStreams ignore:nil],
            [RACObserve(self, preferences.notificationsEnabled) ignore:@NO]]
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
            return RACTuplePack(previous, current); }]
        map:^id(RACTuple *tuple) {
            RACTupleUnpack(NSArray *previous, NSArray *current) = tuple;
            return current.without(previous);
        }] skip:1];

    // Subscribe to -notificationChanges and send a notification for every
    // new stream that we have.
    [[notificationChanges
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
            DDLogInfo(@"Refresh set to %ld seconds.", [interval integerValue] * 60);
        }];

    // We store the stream list refresh time in minutes, so take
    // that value and multiply it by 60 for great justice.
    [[RACSignal interval:[self.preferences.streamListRefreshTime doubleValue] * 60
        onScheduler:[RACScheduler scheduler]]
        subscribeNext:^(id x) {
            @strongify(self);
            DDLogVerbose(@"Triggering timed refresh.");
            [self.viewModel.fetchCommand execute:nil];
        }];

    RACSignal *readySignal = [[AccountManager sharedManager] readySignal];
    RAC(self, emptyMessage, @"") = [[readySignal
        map:^id(NSNumber *isReady) {
            return [isReady boolValue] ? @"Nobody's streaming. :(" : @"Connect to see your follows."; }]
        deliverOn:[RACScheduler mainThreadScheduler]];

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
    RAC(self, errorView.titleLabel.stringValue, @"") = [RACObserve(self, viewModel.errorMessage)
        map:^id(id value) {
            return [self formatError:value];
        }];
    [[[RACObserve(self, viewModel.hasError) skip:1]
        deliverOn:[RACScheduler mainThreadScheduler]]
        subscribeNext:^(NSNumber *hasError) {
            if ([hasError boolValue]) {
                DDLogWarn(@"Showing the error view.");
                [self.view addSubview:self.errorView];
            } else {
                DDLogWarn(@"Removing the error view.");
                [self.errorView removeFromSuperview];
            }
        }];
}

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

    if (section == 0 && [[_listView viewInSection:0 atIndex:0] isMemberOfClass:[StreamListEmptyItemView class]]) {
        [_listView removeListViewItemInSection:0 atIndex:0];
    }

    [[[[toRemove.rac_sequence
        map:^id(StreamViewModel *value) {
            [_listView removeListViewItemForObject:value];
            return [RACSignal return:value]; }] eagerSequence] signal]
        deliverOn:[RACScheduler mainThreadScheduler]];
    [[[[toAdd.rac_sequence
        map:^id(StreamViewModel *value) {
            StreamListItemView *item = [StreamListItemView initItemStream:value];
            [_listView addListViewItem:item inSection:section];
            return [RACSignal return:value]; }] eagerSequence] signal]
        deliverOn:[RACScheduler mainThreadScheduler]];
}

- (void)displayEmptyListItem
{
    if (![[_listView viewInSection:0 atIndex:0] isMemberOfClass:[StreamListEmptyItemView class]]) {
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

#pragma mark - Status Bar Menu

- (void)initializeMenu
{
    // Bind our menu to the application delegate's menu.
    ApplicationController *delegate = [ApplicationController sharedInstance];
    RAC(self, menu) = RACObserve(delegate, menu);
    [[RACObserve(self, menu) ignore:nil]
        subscribeNext:^(id x) {
            [self.menu setDelegate:self];
        }];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSArray *streams = self.viewModel.authenticatedStreams;
    NSUInteger count = [streams count];

    NSMenuItem *countItem = [menu itemWithTag:1111];
    NSMenuItem *separatorItem = [menu itemWithTag:1112];
    if (countItem && !streams.empty) {
        [countItem setTitle:[NSString stringWithFormat:@"%lu live streams", count]];
        [countItem setHidden:NO];
        [separatorItem setHidden:NO];
    } else if (streams.empty) {
        [countItem setHidden:YES];
        [separatorItem setHidden:YES];
    }

    for (NSMenuItem *item in [menu itemArray]) {
        if (item.tag == 9999) { [self.menu removeItem:item]; }
    }

    // Authenticated stream menu items.
    if (count) {
        for (StreamViewModel *viewModel in streams.reverse) {
            NSMenuItem *streamItem = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(openStream:) keyEquivalent:@""];
            StreamMenuItem *view = [StreamMenuItem init];
            [view setViewModel:viewModel];
            [view.name setStringValue:viewModel.displayName];
            [view.game setStringValue:viewModel.game];
            [view.logo setImage:[[NSImage alloc] initWithContentsOfURL:viewModel.logoImageURL]];
            [view.viewers setStringValue:[NSString stringWithFormat:@"%@ viewers", viewModel.viewers]];
            [streamItem setView:view];
            [streamItem setTarget:self];
            [streamItem setTag:9999];
            [self.menu insertItem:streamItem atIndex:1];
        }

        NSMenuItem *separator = [NSMenuItem separatorItem];
        [separator setTag:9999];
        [self.menu insertItem:separator atIndex:1];        
    }
}

- (IBAction)openStream:(NSMenuItem *)sender
{
    StreamMenuItem *view = (StreamMenuItem *)sender.view;
    JAObjectListViewItem *item = [_listView viewItemForObject:view.viewModel];

    // Clear any selections.
    [self clearListViewSelection];

    // Select the desired item.
    [_listView selectView:item];
    [item setSelected:YES];
    [_listView setNeedsDisplay:YES];

    // Open the window!
    [self openWindow:self];
}

- (IBAction)openWindow:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestToOpenWindowNotification object:self userInfo:nil];
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
