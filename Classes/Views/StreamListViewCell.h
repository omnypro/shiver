//
//  StreamListViewCell.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PXListViewCell.h"

@interface StreamListViewCell : PXListViewCell

@property (nonatomic, strong) IBOutlet NSTextField *streamTitleLabel;
@property (nonatomic, strong) IBOutlet NSTextField *streamUserLabel;

@end
