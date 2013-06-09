//
//  WindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class OBMenuBarWindow;

@interface WindowController : NSWindowController

@property (weak) IBOutlet NSView *masterView;
@property (weak) IBOutlet NSView *titleBarView;
@property (weak) IBOutlet NSTextField *statusLabel;

@end
