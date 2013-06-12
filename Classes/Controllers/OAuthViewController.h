//
//  OAuthViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/9/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RHPreferences/RHPreferences.h>
#import <WebKit/WebKit.h>

@interface OAuthViewController : NSViewController <RHPreferencesViewControllerProtocol>

@property (weak) IBOutlet NSButton *loginButton;
@property (weak) IBOutlet NSButton *learnMoreButton;
@property (weak) IBOutlet NSTextField *connectionStatusLabel;

@property (strong) IBOutlet NSWindow *modalWindow;
@property (weak) IBOutlet WebView *modalWebView;

- (IBAction)loginOrLogout:(NSButton *)sender;
- (IBAction)learnMore:(NSButton *)sender;

@end
