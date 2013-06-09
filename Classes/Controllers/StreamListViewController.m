//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListViewController.h"

#import "Overcoat.h"
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

    self._listItems = [[NSMutableArray alloc] init];

    // Create a bunch of rows as a test.
    for( NSInteger i = 0; i < 10; i++ )
    {
        NSString *title = [[NSString alloc] initWithFormat: @"Item %ld", i +1];
        [self._listItems addObject:title];
    }

    [Stream fetchItems];
    [self.listView reloadData];
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
    [[cell streamUserLabel] setStringValue:[self._listItems objectAtIndex:row]];
    [[cell streamTitleLabel] setStringValue:[self._listItems objectAtIndex:row]];
    return cell;
}

- (CGFloat)listView:(PXListView *)aListView heightOfRow:(NSUInteger)row
{
    return 50;
}

- (NSUInteger)numberOfRowsInListView:(PXListView *)aListView
{
	return [self._listItems count];
}

@end
