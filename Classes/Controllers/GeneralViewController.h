//
//  GeneralViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>

@interface GeneralViewController : NSViewController <RHPreferencesViewControllerProtocol>

@property (weak) IBOutlet NSButton *systemStartupCheckbox;
@property (weak) IBOutlet NSButton *notificationCheckbox;
@property (weak) IBOutlet NSTextField *refreshTimeField;

- (IBAction)startOnSystemStartup:(id)sender;
- (IBAction)showDesktopNotifications:(id)sender;
- (IBAction)setStreamListRefreshTime:(id)sender;

@end
