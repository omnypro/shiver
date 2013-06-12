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

@interface StreamListViewController ()

@end

@implementation StreamListViewController

- (void)awakeFromNib
{
    [self.listView setCellSpacing:1.0f];
    [self.listView setAllowsEmptySelection:YES];
    [self.listView setAllowsMultipleSelection:YES];

    [Stream fetchStreamListWithBlock:^(NSArray *streams, NSError *error) {
        if (error) {
            [[NSAlert alertWithMessageText:NSLocalizedString(@"Error", nil) defaultButton:NSLocalizedString(@"OK", nil) alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@",[error localizedDescription]] runModal];
        }

        NSLog(@"streams: %lu", (unsigned long)streams.count);
        NSLog(@"streams: %@", streams);
        self.streamArray = streams;
        NSLog(@"streams mutableCopy: %@", self.streamArray);

        [self.listView reloadData];
    }];
}

#pragma mark - Data Source Methods

- (void)loadItems
{
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
    return self.streamArray.count;
}

@end
