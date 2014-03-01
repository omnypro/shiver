//
//  MainWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/7/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "INAppStoreWindow.h"
#import "StreamListViewController.h"
#import "StreamListViewModel.h"
#import "StreamViewModel.h"
#import "StreamViewerViewController.h"
#import "TitleView.h"
#import "WindowViewModel.h"

#import "MainWindowController.h"

@interface MainWindowController () {
    IBOutlet NSView *_loginView;
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_sidebarView;
    IBOutlet NSView *_userView;
}

@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) NSString *username;

@property (weak) IBOutlet NSImageView *avatar;
@property (weak) IBOutlet NSTextField *usernameLabel;

@end

@implementation MainWindowController

@dynamic viewModel;

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self initializeInterface];
    [self initializeViewControllers];
}

- (void)initializeInterface
{
	INAppStoreWindow *window = (INAppStoreWindow *)[self window];
    [window setTitleBarHeight:38.0];
    [window setTrafficLightButtonsLeftMargin:12.0];
    [window setShowsBaselineSeparator:NO];

    [[RACObserve(self, viewModel.isLoggedIn) map:^id(id value) {
        NSLog(@"value: %@", value);
        return [RACSignal return:value];
    }] subscribeNext:^(id x) {
        NSLog(@"x: %@", x);
    }];

	NSView *titleBarView = window.titleBarView;
    self.titleView.frame = titleBarView.bounds;
    self.titleView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [titleBarView addSubview:_loginView];
    [titleBarView addSubview:self.titleView];

    [[self.usernameLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
    RAC(self, usernameLabel.stringValue, @"") = RACObserve(self, viewModel.name);
    RAC(self, avatar.image, nil) = [RACObserve(self, viewModel.logoImageURL)
        map:^id(NSURL *url) {
            return [[NSImage alloc] initWithContentsOfURL:url];
        }];
}

- (void)initializeViewControllers
{
    StreamListViewModel *listViewModel = [[StreamListViewModel alloc] init];
    self.sidebarController = [[StreamListViewController alloc] initWithViewModel:listViewModel nibName:@"StreamListView" bundle:nil];
    [self.sidebarController.view setFrame:_sidebarView.bounds];
    [_sidebarView addSubview:self.sidebarController.view];

    StreamViewModel *streamViewModel = [[StreamViewModel alloc] init];
    self.viewerController = [[StreamViewerViewController alloc] initWithViewModel:streamViewModel nibName:@"StreamViewer" bundle:nil];
    [self setViewerController:self.viewerController];
    [self.viewerController.view setFrame:_viewer.bounds];
    [_viewer addSubview:self.viewerController.view];
}

#pragma mark - Interface Builder Actions

- (IBAction)login:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RequestToOpenPreferencesNotification object:self userInfo:nil];
}

#pragma - NSWindowDelegate Methods

- (BOOL)windowShouldClose:(id)sender
{
    [self.window orderOut:self];
    return NO;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    DDLogVerbose(@"Application (%@): Displaying main window.", [self class]);
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    DDLogVerbose(@"Application (%@): Hiding main window.", [self class]);
}

- (void)windowWillClose:(NSNotification *)notification
{
    DDLogVerbose(@"Application (%@): Closing main window.", [self class]);
}

@end
