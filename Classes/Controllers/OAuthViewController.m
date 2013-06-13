//
//  OAuthViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "OAuthViewController.h"

#import "APIClient.h"
#import "User.h"

@interface OAuthViewController ()

@end

@implementation OAuthViewController

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
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];

    if ([[APIClient sharedClient] isAuthenticated]) {
        [User userWithBlock:^(User *user, NSError *error) {
            if (user) { [self.connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", user.name]]; }
        }];
        [self.loginButton setTitle:@"Disconnect Twitch"];
    }
}

#pragma mark - Sheet Lifecycle Methods

- (void)getURL:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"urlString: %@", urlString);

    NSURL *url = [NSURL URLWithString:urlString];
    NSLog(@"urlQueryParams: %@", [url query]);

    if (url && [[url query] rangeOfString:@"access_denied"].location != NSNotFound) {
        [NSApp endSheet:self.modalWindow];
        [self didEndSheet:self.modalWindow returnCode:0 contextInfo:nil];
    }
    if (url && [[url fragment] rangeOfString:@"access_token"].location != NSNotFound) {
        [[APIClient sharedClient] authorizeUsingResponseURL:url];

        // Update the interface.
        [User userWithBlock:^(User *user, NSError *error) {
            [self.connectionStatusLabel setStringValue:[NSString stringWithFormat:@"You're logged in as %@.", user.name]];
            [self.loginButton setTitle:@"Disconnect Twitch"];
            [[NSNotificationCenter defaultCenter] postNotificationName:UserDidConnectAccountNotification object:self userInfo:nil];
        }];
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}

#pragma mark - RHPreferencesViewControllerProtocol

- (NSString*)identifier
{
    return NSStringFromClass(self.class);
}

- (NSImage*)toolbarItemImage
{
    return [NSImage imageNamed:@"TwitchGlitchPurple"];
}

-(NSString*)toolbarItemLabel
{
    return NSLocalizedString(@"Twitch", @"OAuthToolbarItemLabel");
}

#pragma mark - WebFrameLoadDelgate Methods

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{

}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{

}

- (IBAction)loginOrLogout:(NSButton *)sender
{
    if ([[APIClient sharedClient] isAuthenticated]) {
        [[APIClient sharedClient] logout];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitch.tv/settings/applications"]];

        // Update the interface.
        [self.connectionStatusLabel setStringValue:@"Not currently connected."];
        [self.loginButton setTitle:@"Connect With Twitch"];

        // Alert the residents!
        [[NSNotificationCenter defaultCenter] postNotificationName:UserDidDisconnectAccountNotification object:self userInfo:nil];
    } else {
        NSString *authorizationURL = [NSString stringWithFormat:@"%@oauth2/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=user_read", kTwitchBaseURL, kClientID, kRedirectURI];
        [self.modalWebView setMainFrameURL:authorizationURL];

        [[NSApplication sharedApplication] beginSheet:self.modalWindow modalForWindow:self.view.window modalDelegate:self didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction)learnMore:(NSButton *)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://twitch.tv"]];
}

@end
