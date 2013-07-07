//
//  GeneralViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "Preferences.h"
#import "StartAtLoginController.h"

#import "GeneralViewController.h"

@interface GeneralViewController () {
    IBOutlet NSButton *_systemStartupCheckbox;
    IBOutlet NSButton *_notificationCheckbox;
    IBOutlet NSButton *_streamCountCheckbox;
    IBOutlet NSBox *_separatorBox;
    IBOutlet NSTextField *_refreshTimeField;
    IBOutlet NSButton *_openInPopupCheckbox;
}

- (IBAction)toggleStartOnSystemStartup:(id)sender;
- (IBAction)toggleShowDesktopNotifications:(id)sender;
- (IBAction)toggleDisplayStreamCount:(id)sender;
- (IBAction)setStreamListRefreshTime:(id)sender;
- (IBAction)toggleOpenStreamsInPopup:(id)sender;
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
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    [_systemStartupCheckbox setState:[loginController startAtLogin]];

    [_notificationCheckbox setState:self.preferences.notificationsEnabled];
    [_streamCountCheckbox setState:self.preferences.streamCountEnabled];
    [_refreshTimeField setIntegerValue:self.preferences.streamListRefreshTime / 60];
    [_openInPopupCheckbox setState:self.preferences.streamPopupEnabled];
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

- (IBAction)toggleStartOnSystemStartup:(id)sender
{
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    if ([_systemStartupCheckbox state]) {
        if (![loginController startAtLogin]) { [loginController setStartAtLogin:YES]; }
    }
    else {
        if ([loginController startAtLogin]) { [loginController setStartAtLogin:NO]; }
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
        [[self preferences] setStreamListRefreshTime:[_refreshTimeField integerValue] * 60];
        DDLogInfo(@"Preferences: Stream list will be refreshed every %ld minutes.", [_refreshTimeField integerValue]);
    }
}

- (IBAction)toggleOpenStreamsInPopup:(id)sender
{
    if ([_openInPopupCheckbox state]) {
        [[self preferences] setStreamPopupEnabled:YES];
        DDLogInfo(@"Preferences: Streams will be displayed in their popup form.");
    }
    else {
        [[self preferences] setStreamPopupEnabled:NO];
        DDLogInfo(@"Preferences: Streams will be displayed normally.");
    }
}

@end
