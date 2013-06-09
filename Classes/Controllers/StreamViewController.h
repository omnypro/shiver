//
//  StreamViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "PXListView.h"

#import <Cocoa/Cocoa.h>

@interface StreamViewController : NSViewController <PXListViewDelegate>

@property (weak) IBOutlet PXListView *listView;
@property (nonatomic, strong) NSMutableArray *_listItems;

@end
