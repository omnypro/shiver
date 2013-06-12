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
    [Stream fetchStreamListWithBlock:^(NSArray *streams, NSError *error) {
        if (error) { NSLog(@"%@", [error localizedDescription]); }
        self.streamArray = streams;

        // Update the interface, starting with the number of live streams.
        WindowController *window = [[WindowController alloc] init];
        [[window statusLabel] setStringValue:[NSString stringWithFormat:@"%lu live streams", (unsigned long)[self.streamArray count]]];
//        [[window lastUpdatedLabel] = ]

        // Reload the listView.
        [self.listView reloadData];
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

    NSString *truncatedTitleLabel = [[stream.channel.status substringToIndex:50] stringByAppendingString:@"..."];
    [[cell streamTitleLabel] setStringValue:truncatedTitleLabel];
    [[cell streamUserLabel] setStringValue:[NSString stringWithFormat:@"%@ playing %@", stream.channel.displayName, stream.game]];
    return cell;
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row
{
    return 60;
}

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView
{
    return [self.streamArray count];
}

@end
