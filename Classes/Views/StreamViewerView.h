//
//  StreamViewerView.h
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "RBLView.h"

@interface StreamViewerView : RBLView

@property (weak) IBOutlet NSButton *chatButton;
@property (weak) IBOutlet NSButton *profileButton;
@property (weak) IBOutlet NSTextField *liveSinceLabel;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSImageView *logo;

- (NSAttributedString *)attributedStatusWithString:(NSString *)string;

@end
