//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListViewController.h"

#import "Channel.h"
#import "PXListViewDelegate.h"
#import "PXListView.h"
#import "Stream.h"
#import "StreamListViewCell.h"
#import "WindowController.h"

@interface StreamListViewController ()
- (void)loadStreamList;
@end

@implementation StreamListViewController

- (void)awakeFromNib
{
    [self.listView setCellSpacing:1];
    [self.listView setAllowsEmptySelection:YES];
    [self.listView setAllowsMultipleSelection:YES];
    [self loadStreamList];
}

#pragma mark - Data Source Methods

- (void)loadStreamList
{
    [Stream streamListWithBlock:^(NSArray *streams, NSError *error) {
        if (error) { NSLog(@"%@", [error localizedDescription]); }
        self.streamArray = streams;

        // Reload the listView and send a notification that the list was
        // reloaded so other parts of the application can update their UIs.
        [self.listView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:StreamListWasUpdatedNotification object:self userInfo:nil];
    }];
}

#pragma mark - ListView Methods

- (PXListViewCell *)listView:(PXListView *)aListView cellForRow:(NSUInteger)row
{
    StreamListViewCell *cell = (StreamListViewCell *)[aListView dequeueCellWithReusableIdentifier:@"Cell"];
    if (!cell) {    
        cell = [StreamListViewCell cellLoadedFromNibNamed:@"StreamListViewCell" bundle:nil reusableIdentifier:@"Cell"];
    }

    // Set up our new cell.
    Stream *stream = [self.streamArray objectAtIndex:row];

    [[cell streamLogo] setImage:[[NSImage alloc] initWithContentsOfURL:stream.channel.logoImageURL]];
    [[cell streamTitleLabel] setStringValue:stream.channel.status];
    [[cell streamUserLabel] setStringValue:[NSString stringWithFormat:@"%@ playing %@", stream.channel.displayName, stream.game]];
    [[cell streamViewerCountLabel] setStringValue:[NSString stringWithFormat:@"%@ viewers", stream.viewers]];
    return cell;
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row
{
    return 70;
}

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView
{
    return [self.streamArray count];
}

@end
