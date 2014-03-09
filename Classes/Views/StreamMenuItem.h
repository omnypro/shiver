//
//  StreamMenuItem.h
//  Shiver
//
//  Created by Bryan Veloso on 3/8/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

@class StreamViewModel;

@interface StreamMenuItem : NSView

@property (nonatomic, strong) StreamViewModel *viewModel;

@property (weak) IBOutlet NSImageView *logo;
@property (weak) IBOutlet NSTextField *name;
@property (weak) IBOutlet NSTextField *game;
@property (weak) IBOutlet NSTextField *viewers;

+ (id)init;

@end
