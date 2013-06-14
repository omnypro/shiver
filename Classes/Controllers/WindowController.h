//
//  WindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@class OBMenuBarWindow;

@interface WindowController : NSWindowController

@property (strong) RHPreferencesWindowController *preferencesWindowController;

@property (weak) IBOutlet NSView *masterView;
@property (weak) IBOutlet NSView *titleBarView;
@property (weak) IBOutlet NSImageView *liveStreamImage;
@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSButton *refreshButton;
@property (weak) IBOutlet NSTextField *lastUpdatedLabel;
@property (weak) IBOutlet NSButton *preferencesButton;

@property (strong) IBOutlet NSMenu *contextMenu;

- (IBAction)showContextMenu:(NSButton *)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)refreshStreamList:(NSButton *)sender;
- (void)streamListWasUpdated:(NSNotification *)notification;

@end
