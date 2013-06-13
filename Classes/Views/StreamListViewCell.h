//
//  StreamListViewCell.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "StreamImageView.h"
#import "PXListViewCell.h"

@interface StreamListViewCell : PXListViewCell

@property (weak) IBOutlet StreamImageView *streamLogo;
@property (weak) IBOutlet NSTextField *streamTitleLabel;
@property (weak) IBOutlet NSTextField *streamUserLabel;
@property (weak) IBOutlet NSTextField *streamViewerCountLabel;
@property (weak) IBOutlet NSButton *streamRedirectButton;

@end
