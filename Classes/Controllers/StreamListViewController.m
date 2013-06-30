//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>

#import "APIClient.h"
#import "Channel.h"
#import "EmptyErrorView.h"
#import "NSColor+Hex.h"
#import "OAuthViewController.h"
#import "JAListView.h"
#import "Preferences.h"
#import "SORelativeDateTransformer.h"
#import "Stream.h"
#import "StreamListViewItem.h"
#import "User.h"
#import "WindowController.h"

#import "StreamListViewController.h"

@interface StreamListViewController () {
    IBOutlet JAListView *_listView;
}

// Legacy
@property (nonatomic, strong) NSMutableArray *_listItems;
@property (nonatomic, strong, readwrite) NSArray *streamArray;

// Views.
@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) RACCommand *refreshCommand;
@property (nonatomic, strong) WindowController *windowController;

// Data sources.
@property (nonatomic, strong) APIClient *client;
@property (nonatomic, strong) NSArray *streamList;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSDate *lastUpdatedTimestamp;

// Controller state.
@property (nonatomic, strong) Preferences *preferences;
@property (atomic) BOOL showingError;
@property (atomic) NSString *showingErrorMessage;
@property (atomic) BOOL showingEmpty;
@property (atomic) BOOL showingLoading;

- (void)sendNewStreamNotificationToUser:(NSSet *)newSet;
@end

@implementation StreamListViewController

- (id)initWithUser:(User *)user
{
    self = [super initWithNibName:@"StreamListView" bundle:nil];
    if (self == nil) { return nil; }

    self.user = user;
    self.statusItem = [[NSApp delegate] statusItem];
    self.preferences = [Preferences sharedPreferences];
    self.windowController = [[NSApp delegate] windowController];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    [self setUpViewSignals];
    [self setUpDataSignals];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setCanCallDataSourceInParallel:YES];
}

- (void)setUpViewSignals
{
    @weakify(self);

    self.refreshCommand = [RACCommand command];
    self.windowController.refreshButton.rac_command = self.refreshCommand;
    [self.refreshCommand subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Stream List: Request to manually refresh the stream list.");
        self.client = [APIClient sharedClient];
    }];

    // Watch the stream list for changes and enable or disable UI elements
    // based on those values.
    [[RACAble(self.streamList) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *array) {
        @strongify(self);
        if ([array count] > 0) {
            // Set the status item's title to the number of live streams if the
            // user has asked for it in the preferences.
            if (self.preferences.streamCountEnabled) {
                [self.statusItem setTitle:[NSString stringWithFormat:@"%lu", [array count]]];
            }

            [self.windowController.lastUpdatedLabel setHidden:NO];
            [self.windowController.refreshButton setEnabled:YES];

            // Update the string based on the number of streams that are live.
            NSString *singularCount = [NSString stringWithFormat:@"%lu live stream", [array count]];
            NSString *pluralCount = [NSString stringWithFormat:@"%lu live streams", [array count]];
            if ([array count] == 1) { [self.windowController.statusLabel setStringValue:singularCount]; }
            else if ([array count] > 1) { [self.windowController.statusLabel setStringValue:pluralCount]; }
            else { [self.windowController.statusLabel setStringValue:@"No live streams"]; }
        }
        else {
            [self.statusItem setTitle:nil];
            [self.windowController.lastUpdatedLabel setHidden:YES];
            [self.windowController.refreshButton setEnabled:NO];
            [self.windowController.statusLabel setStringValue:@"No live streams"];
        }
    }];

    // Updated the lastUpdated label every 30 seconds.
    NSTimeInterval lastUpdatedInterval = 30.0;
    [[[RACAbleWithStart(self.streamList) map:^id(id value) {
        return [RACSignal interval:lastUpdatedInterval];
    }] switchToLatest] subscribeNext:^(NSArray *array) {
        NSLog(@"Stream List: Updating the last updated label (on interval).");
        if (array != nil) { [self updateLastUpdatedLabel]; }
    }];

    // Show or hide the empty view.
    [[[RACAble(self.showingEmpty) distinctUntilChanged] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *showingEmpty) {
         @strongify(self);
         BOOL isShowingEmpty = [showingEmpty boolValue];
         if (isShowingEmpty && !self.showingError){
             NSLog(@"Stream List: Showing the empty view.");
             NSString *title = @"Looks like you've got nothing to watch.";
             NSString *subTitle = @"Why don't you follow some new streamers?";
             self.errorView = [[EmptyErrorView init] emptyViewWithTitle:title subTitle:subTitle];
             [self.view addSubview:self.emptyView];
         } else {
             NSLog(@"Stream List: Removing the empty view.");
             [self.emptyView removeFromSuperview];
             self.emptyView = nil;
         }
     }];

    // Show or hide the error view.
    [[[RACAble(self.showingError) distinctUntilChanged] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *showingError) {
         @strongify(self);
         BOOL isShowingError = [showingError boolValue];
         if (isShowingError) {
             // Don't show the empty or loading views if there's an error.
             self.showingEmpty = NO;
             self.showingLoading = NO;
             NSString *title = @"Whoops! Something went wrong.";
             NSString *message = self.showingErrorMessage ? self.showingErrorMessage : @"Undefined error.";
             NSLog(@"Stream List: Showing the error view with message \"%@\"", message);
             self.errorView = [[EmptyErrorView init] errorViewWithTitle:title subTitle:message];
             [self.view addSubview:self.errorView];
             [self.errorView setNeedsDisplay:YES];
         }
         else {
             NSLog(@"Stream List: Removing the error view.");
             [self.errorView removeFromSuperview];
             self.errorView = nil;
             self.showingErrorMessage = nil;
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
        NSLog(@"Stream List: Loading client for %@.", user.name);
        @strongify(self);
        self.client = [APIClient sharedClient];
    }];

    // Watch for `client` to change or be populated. If so, fetch the stream
    // list and assign it.
    [[[RACAbleWithStart(self.client) filter:^BOOL(id value) {
        return (value != nil);
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        @strongify(self);
        [[[self.client fetchStreamList] deliverOn:[RACScheduler scheduler]] subscribeNext:^(NSArray *streamList) {
            NSLog(@"Stream List: Fetching the stream list.");
            @strongify(self);
            self.streamList = streamList;
            self.showingError = NO;
            self.showingLoading = YES;
        } error:^(NSError *error) {
            @strongify(self);
            NSLog(@"Stream List: (Error) %@", error);
            self.showingErrorMessage = [error localizedDescription];
            self.showingError = YES;
        }];
    }];

    // When the stream list gets changed, reload the table.
    [[RACAble(self.streamList) deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x){
         @strongify(self);
         NSLog(@"Stream List: Refreshing the stream list.");
         NSLog(@"Stream List: %lu live streams.", [x count]);

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
            NSLog(@"Notifications: %lu new streams.", (unsigned long)[xorSet count]);
            [self sendNewStreamNotificationToUser:xorSet];
        }
    }];

    // Refresh the stream list at an interval provided by the user.
    [[RACAbleWithStart(self.preferences.streamListRefreshTime) distinctUntilChanged] subscribeNext:^(NSNumber *interval) {
        NSLog(@"Stream List: Refresh set to %ld seconds.", [interval integerValue]);
    }];
    [[RACSignal interval:self.preferences.streamListRefreshTime] subscribeNext:^(id x) {
        @strongify(self);
        NSLog(@"Stream List: Triggering timed refresh.");
        self.client = [APIClient sharedClient];
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
    NSString *relativeStringValue = [NSString stringWithFormat:@"Last updated %@", relativeDate];
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
    Stream *stream = [self.streamList objectAtIndex:index];
    StreamListViewItem *item = [StreamListViewItem initItem];
    
    item.object = stream;
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
