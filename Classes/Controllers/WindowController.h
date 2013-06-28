//
//  WindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface WindowController : NSWindowController

@property (nonatomic, strong, readonly) RHPreferencesWindowController *preferencesWindowController;

// These are controls that need to be accessed from the stream list controller.
@property (weak) IBOutlet NSButton *refreshButton;
@property (weak) IBOutlet NSTextField *lastUpdatedLabel;
@property (weak) IBOutlet NSTextField *statusLabel;

@end
