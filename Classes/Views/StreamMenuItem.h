//
//  StreamMenuItem.h
//  Shiver
//
//  Created by Bryan Veloso on 3/8/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

@interface StreamMenuItem : NSView

@property (weak) IBOutlet NSImageView *logo;
@property (weak) IBOutlet NSTextField *name;
@property (weak) IBOutlet NSTextField *game;

+ (id)init;

@end
