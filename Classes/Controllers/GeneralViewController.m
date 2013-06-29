//
//  GeneralViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/20/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StartAtLoginController.h"

#import "GeneralViewController.h"

@interface GeneralViewController () {
    IBOutlet NSButton *_systemStartupCheckbox;
    IBOutlet NSButton *_notificationCheckbox;
    IBOutlet NSButton *_streamCountCheckbox;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    StartAtLoginController *loginController = [[StartAtLoginController alloc] initWithIdentifier:ShiverHelperIdentifier];
    if (![loginController startAtLogin]) { [_systemStartupCheckbox setState:NSOffState]; }
    if ([loginController startAtLogin]) { [_systemStartupCheckbox setState:NSOnState]; }
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier
{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage
{
    return [NSImage imageNamed:@""];
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

- (IBAction)showDesktopNotifications:(id)sender
{

}

- (IBAction)toggleDisplayStreamCount:(id)sender {
}

- (IBAction)setStreamListRefreshTime:(id)sender
{

}

- (IBAction)toggleOpenStreamsInPopup:(id)sender {
}

@end
