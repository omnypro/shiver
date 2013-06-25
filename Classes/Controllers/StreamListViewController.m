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
#import "Stream.h"
#import "StreamListViewItem.h"
#import "User.h"
#import "WindowController.h"

#import "StreamListViewController.h"

@interface StreamListViewController () {
    IBOutlet JAListView *_listView;

@private
    dispatch_source_t _timer;
}

// Legacy
@property (nonatomic, strong) NSMutableArray *_listItems;
@property (nonatomic, strong, readwrite) NSArray *streamArray;

// Views.
@property (nonatomic, strong) NSView *emptyView;
@property (nonatomic, strong) NSView *errorView;

// Data sources.
@property (atomic, strong) User *user;
@property (atomic, strong) APIClient *client;
@property (atomic, strong) NSArray *streamList;

// Controller state.
@property (atomic) BOOL showingError;
@property (atomic) NSString *showingErrorMessage;
@property (atomic) BOOL showingEmpty;
@property (atomic) BOOL showingLoading;

- (NSSet *)compareExistingStreamList:(NSArray *)existingArray withNewList:(NSArray *)newArray;
- (void)loadStreamList;
- (void)sendNewStreamNotificationToUser:(NSSet *)newSet;
@end

@implementation StreamListViewController

- (id)initWithUser:(User *)user
{
    self = [super initWithNibName:@"StreamListView" bundle:nil];
    if (self == nil) { return nil; }

    self.user = user;
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestStreamListRefresh:) name:RequestToUpdateStreamNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDisconnectedAccount:) name:UserDidDisconnectAccountNotification object:nil];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    [self setUpViewSignals];
    [self setUpDataSignals];

    [_listView setBackgroundColor:[NSColor clearColor]];
    [_listView setCanCallDataSourceInParallel:YES];
    // [self loadStreamList];
    // [self startTimerForLoadingStreamList];
}

- (void)setUpViewSignals
{
    @weakify(self);

    // Show or hide the empty view.
    [[[RACAble(self.showingEmpty) distinctUntilChanged] deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(NSNumber *showingEmpty) {
         @strongify(self);
         BOOL isShowingEmpty = [showingEmpty boolValue];
         if (isShowingEmpty && !self.showingError){
             self.errorView = [[EmptyErrorView init] emptyViewWithTitle:nil subTitle:nil];
             [self.view addSubview:self.emptyView];
         } else {
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
             NSLog(@"Showing the error view...");
             self.showingEmpty = NO;
             self.showingLoading = NO;
             NSString *message = self.showingErrorMessage ? self.showingErrorMessage : @"Undefined error.";
             self.errorView = [[EmptyErrorView init] errorViewWithTitle:message subTitle:message];
             [self.view addSubview:self.errorView];
             [self.errorView setNeedsDisplay:YES];
         }
         else {
             NSLog(@"Removing the error view...");
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
        return (value == nil); // @@@ Do we really want to pass a user at all?
    }] subscribeNext:^(id x) {
        NSLog(@"Loading client...");
        @strongify(self);
        self.client = [APIClient sharedClient];
    }];

    // Watch for `client` to change or be populated. If so, fetch the stream
    // list and assign it.
    [[[RACAbleWithStart(self.client) filter:^BOOL(id value) {
        return (value != nil);
    }] deliverOn:[RACScheduler scheduler]] subscribeNext:^(id x) {
        NSLog(@"Fetching stuff...");
        @strongify(self);
        [[[self.client fetchStreamList] deliverOn:[RACScheduler scheduler]] subscribeNext:^(NSArray *streamList) {
            @strongify(self);
            self.streamList = streamList;
            self.showingLoading = YES;
        } error:^(NSError *error) {
            @strongify(self);
            NSLog(@"Oh no, an error...");
            NSLog(@"error: %@", error);
            self.showingErrorMessage = [error localizedDescription];
            self.showingError = YES;
        }];
    }];

    // When the stream list gets changed, reload the table.
    [[RACAble(self.streamList) deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(id x){
         @strongify(self);
         NSLog(@"Refreshing the stream list...");

         // JAListView includes an internal padding function! So, when the list
         // is longer than two (which creates scrolling behavior, add 5 points
         // to the bottom of the view.
         if (self.streamList.count > 2) {
             [_listView setPadding:JAEdgeInsetsMake(0, 0, 5, 0)];
         }

         // Reload the table.
         [_listView reloadData];
         self.showingLoading = NO;
     }];

    // Monitor the data source array and show an empty view if it's... empty.
    [RACAble(self.streamList) subscribeNext:^(NSArray *streamList) {
        @strongify(self);
        if ((streamList == nil) || ([streamList count] == 0)) { self.showingEmpty = YES; }
        else { self.showingEmpty = NO; }
    }];
}

#pragma mark - Data Source Methods

- (void)startTimerForLoadingStreamList
{
    // Schedule a timer to run `loadStreamList` every 5 minutes (300 seconds).
    // Keep a strong reference to _timer in ARC.
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 300.0 * NSEC_PER_SEC, 1.0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{ [self loadStreamList]; });
    dispatch_resume(_timer);
}

- (void)loadStreamList
{
    [Stream streamListWithBlock:^(NSArray *streams, NSError *error) {
        if (error) { NSLog(@"%@", [error localizedDescription]); }

        // If we have no streams, brodacast a notification so other parts
        // of the application can update their UIs.
        if (streams.count == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:StreamListIsEmptyNotification object:self userInfo:nil];
        }
        else {
            // If we've fetched streams before, compared the existing list to
            // the newly fetched one to check for any new broadcasts. If so,
            // send those streams to the notification center.
            if (self.streamArray != nil) {
                NSSet *newBroadcasts = [self compareExistingStreamList:self.streamArray withNewList:streams];
                [self sendNewStreamNotificationToUser:newBroadcasts];
            }

            self.streamArray = streams;

            // Send a notification that the list was reloaded so other parts
            // of the application can update their UIs.
            [[NSNotificationCenter defaultCenter] postNotificationName:StreamListWasUpdatedNotification object:self userInfo:nil];
        }

        // Reload the listView.
        [_listView reloadDataAnimated:YES];
    }];
}

- (NSSet *)compareExistingStreamList:(NSArray *)existingArray withNewList:(NSArray *)newArray
{
    // Take the `_id` value of each stream in the existing array subtract those
    // that exist in the recently fetched array. Notifications will be sent for
    // the results.
    NSSet *existingStreamSet = [NSSet setWithArray:existingArray];
    NSSet *existingStreamSetIDs = [existingStreamSet valueForKey:@"_id"];
    NSSet *newStreamSet = [NSSet setWithArray:newArray];
    NSSet *xorSet = [newStreamSet filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"NOT _id IN %@", existingStreamSetIDs]];
    return xorSet;
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
        [notification setUserInfo:@{ @"URL": [stream.channel.url absoluteString] }];

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
    NSLog(@"object: %@", item.object);
    return item;
}

- (NSUInteger)numberOfItemsInListView:(JAListView *)listView
{
    if (self.streamList != nil) {
        return [self.streamList count];
    }
    return 0;
}

#pragma mark - Notification Observers

- (void)requestStreamListRefresh:(NSNotification *)notification
{
    WindowController *object = [notification object];
    if ([object isKindOfClass:[WindowController class]]) {
        // The refresh button should reinstantiate the client to trigger the
        // reactions. Not sure if this is the correct way to do this.
        self.client = [APIClient sharedClient];
        // [self loadStreamList];
    }
}

- (void)userDisconnectedAccount:(NSNotification *)notification
{
    OAuthViewController *object = [notification object];
    if ([object isKindOfClass:[OAuthViewController class]]) {
        // Ah, don't forget we have a timer. We should stop it.
        dispatch_source_cancel(_timer);
    }
}

@end
