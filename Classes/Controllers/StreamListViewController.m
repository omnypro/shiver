//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListViewController.h"

#import "AFImageRequestOperation.h"
#import "Channel.h"
#import "NSColor+Hex.h"
#import "NSImageView+AFNetworking.h"
#import "OAuthViewController.h"
#import "JAListView.h"
#import "Stream.h"
#import "StreamListViewItem.h"
#import "WindowController.h"

@interface StreamListViewController () {
@private
    dispatch_source_t _timer;
}

- (NSSet *)compareExistingStreamList:(NSArray *)existingArray withNewList:(NSArray *)newArray;
- (void)sendNewStreamNotificationToUser:(NSSet *)newSet;
@end

@implementation StreamListViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestStreamListRefresh:) name:RequestToUpdateStreamNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDisconnectedAccount:) name:UserDidDisconnectAccountNotification object:nil];

    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    [center setDelegate:self];

    [self.listView setBackgroundColor:[NSColor clearColor]];
    [self.listView setCanCallDataSourceInParallel:YES];

    [self loadStreamList];
    [self startTimerForLoadingStreamList];
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

        // JAListView includes an internal padding function! So, when the list
        // is longer than two (which creates scrolling behavior, add 5 points
        // to the bottom of the view.
        if (self.streamArray.count > 2) {
            [self.listView setPadding:JAEdgeInsetsMake(0, 0, 5, 0)];
        }

        // Reload the listView.
        [self.listView reloadDataAnimated:YES];
        [self.listView reloadData];
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
    if (listView == self.listView) {
        return;
    }
}

- (void)listView:(JAListView *)listView didSelectView:(JAListViewItem *)view
{
    if (listView == self.listView) {
        return;
    }
}

- (void)listView:(JAListView *)listView didDeselectView:(JAListViewItem *)view
{
    if (listView == self.listView) {
        return;
    }
}

#pragma mark - JAListViewDataSource Methods

- (JAListViewItem *)listView:(JAListView *)listView viewAtIndex:(NSUInteger)index
{
    Stream *stream = [self.streamArray objectAtIndex:index];
    StreamListViewItem *item = [StreamListViewItem initItem];

    // Asynchronously load the two images required for every stream cell.
    [item.streamPreview setImageWithURLRequest:[NSURLRequest requestWithURL:stream.previewImageURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
        [item.streamPreview setImage:image];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"%@", error);
    }];
    [item.streamLogo setImageWithURLRequest:[NSURLRequest requestWithURL:stream.channel.logoImageURL] placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSImage *image) {
        [item.streamLogo setImage:image];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        NSLog(@"%@", error);
    }];

    NSMutableAttributedString *attrStreamTitle = [[NSMutableAttributedString alloc] initWithString:stream.channel.status];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:14];
    [attrStreamTitle addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attrStreamTitle length])];
    [item.streamTitleLabel setAttributedStringValue:attrStreamTitle];

    [item.streamUserLabel setStringValue:stream.channel.displayName];
    [item.streamUserLabel setTextColor:[NSColor colorWithHex:@"#4A4A4A"]];

    [item.streamGameLabel setStringValue:stream.game];
    [item.streamGameLabel setTextColor:[NSColor colorWithHex:@"#9D9D9E"]];

    [item.streamViewerCountLabel setStringValue:[NSString stringWithFormat:@"%@", stream.viewers]];
    
    return item;
}

- (NSUInteger)numberOfItemsInListView:(JAListView *)listView
{
    return [self.streamArray count];
}

#pragma mark - Notification Observers

- (void)requestStreamListRefresh:(NSNotification *)notification
{
    WindowController *object = [notification object];
    if ([object isKindOfClass:[WindowController class]]) {
        [self loadStreamList];
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
