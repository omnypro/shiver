//
//  GeneralViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Preferences.h"

#import "GeneralViewController.h"

@interface GeneralViewController () {
    IBOutlet NSPopUpButton *_iconVisibilityPopUp;
    IBOutlet NSButton *_systemStartupCheckbox;
    IBOutlet NSButton *_notificationCheckbox;
    IBOutlet NSButton *_streamCountCheckbox;
    IBOutlet NSTextField *_refreshTimeField;
}

- (IBAction)toggleIconVisibility:(id)sender;
- (IBAction)toggleStartOnSystemStartup:(id)sender;
- (IBAction)toggleShowDesktopNotifications:(id)sender;
- (IBAction)toggleDisplayStreamCount:(id)sender;
- (IBAction)setStreamListRefreshTime:(id)sender;

@end

@implementation GeneralViewController

- (Preferences *)preferences
{
    if (_preferences == nil) { _preferences = [Preferences sharedPreferences]; }
    return _preferences;
}

- (id)init
{
    self = [super initWithNibName:@"GeneralView" bundle:nil];
    if (self == nil) { return nil; }
    return self;
}

- (void)awakeFromNib
{
    [_systemStartupCheckbox setState:self.preferences.autoStartEnabled];
    [_notificationCheckbox setState:self.preferences.notificationsEnabled];
    [_streamCountCheckbox setState:self.preferences.streamCountEnabled];
    [_refreshTimeField setIntegerValue:[self.preferences.streamListRefreshTime integerValue]];
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier
{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage
{
    return [NSImage imageNamed:@"PreferencesGeneral"];
}

-(NSString*)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"GeneralToolbarItemLabel");
}

- (IBAction)toggleIconVisibility:(id)sender
{
    NSUInteger item = [[sender objectValue] integerValue];
    NSLog(@"%lu", item);

    switch (item) {
        case 0:  // Dock and Menu Bar.
            [[self preferences] setIconVisibility:@0];
            DDLogInfo(@"Preferences: Shiver will appear in the dock and menu bar.");
            break;
        case 1:  // Only Dock.
            [[self preferences] setIconVisibility:@1];
            DDLogInfo(@"Preferences: Shiver will only appear in the dock.");
            break;
        case 2:  // Only Menu Bar.
            [[self preferences] setIconVisibility:@2];
            DDLogInfo(@"Preferences: Shiver will only appear in the menu bar.");
            break;
        default:
            break;
    }
}

- (IBAction)toggleStartOnSystemStartup:(id)sender
{
    if ([_systemStartupCheckbox state]) {
        [[self preferences] setAutoStartEnabled:YES];
        DDLogInfo(@"Preferences: Launch agent has been enabled.");
    }
    else {
        [[self preferences] setAutoStartEnabled:NO];
        DDLogInfo(@"Preferences: Launch agent has been disabled.");
    }
}

- (IBAction)toggleShowDesktopNotifications:(id)sender
{
    if ([_notificationCheckbox state]) {
        [[self preferences] setNotificationsEnabled:YES];
        DDLogInfo(@"Preferences: Notifications have been enabled.");
    }
    else {
        [[self preferences] setNotificationsEnabled:NO];
        DDLogInfo(@"Preferences: Notifications have been disabled.");
    }
}

- (IBAction)toggleDisplayStreamCount:(id)sender
{
    if ([_streamCountCheckbox state]) {
        [[self preferences] setStreamCountEnabled:YES];
        DDLogInfo(@"Preferences: Stream count will be displayed in the menu item.");
    }
    else {
        [[self preferences] setStreamCountEnabled:NO];
        DDLogInfo(@"Preferences: Stream count will not be displayed in the menu item.");
    }
}

- (IBAction)setStreamListRefreshTime:(id)sender
{
    if ([_refreshTimeField integerValue] > 0) {
        [[self preferences] setStreamListRefreshTime:[NSNumber numberWithInteger:[_refreshTimeField integerValue]]];
        DDLogInfo(@"Preferences: Stream list will be refreshed every %ld minutes.", [_refreshTimeField integerValue]);
    }
}

@end
