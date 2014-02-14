//
//  MainWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/7/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "INAppStoreWindow.h"
#import "StreamListViewController.h"
#import "MainWindowController.h"
#import "WindowViewModel.h"

@interface MainWindowController () {
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_listView;
    IBOutlet NSView *_streamView;
}

@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) NSViewController *listViewController;
@property (nonatomic, strong) NSViewController *streamViewController;

@end

@implementation MainWindowController

@dynamic viewModel;

- (void)windowDidLoad
{
    [super windowDidLoad];

    [self initializeInterface];

    StreamListViewController *listController = [[StreamListViewController alloc] initWithUser:nil];
    [self setListViewController:listController];
}

- (void)initializeInterface
{
	INAppStoreWindow *window = (INAppStoreWindow *)[self window];
    [window setTitleBarHeight:38.0];
    [window setTrafficLightButtonsLeftMargin:12.0];

	NSView *titleBarView = window.titleBarView;

    NSSize labelSize = NSMakeSize(104, 20);
	NSRect labelFrame = NSMakeRect(NSMidX(titleBarView.bounds) - (labelSize.width / 2.f), NSMidY(titleBarView.bounds) - (labelSize.height / 2.f), labelSize.width, labelSize.height);
    NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    RAC(label, stringValue, @"") = RACObserve(self, viewModel.name);
    [titleBarView addSubview:label];
}

#pragma mark - Window Compositioning

- (void)setListViewController:(NSViewController *)viewController {
    if (_listViewController == viewController) { return; }

    _listViewController = viewController;
    [_listViewController.view setFrame:_listView.bounds];
    [_listView addSubview:self.listViewController.view];
}

- (void)setStreamViewController:(NSViewController *)viewController {
    if (_streamViewController == viewController) { return; }

    _streamViewController = viewController;
    [_streamViewController.view setFrame:_streamView.bounds];
    [_streamView addSubview:self.streamViewController.view];
}

@end
