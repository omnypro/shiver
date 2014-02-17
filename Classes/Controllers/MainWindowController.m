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
#import "WindowViewModel.h"

#import "MainWindowController.h"

@interface MainWindowController () {
    IBOutlet NSView *_masterView;
    IBOutlet NSView *_sidebarView;
}

@property (nonatomic, strong) NSView *errorView;
@property (nonatomic, strong) NSViewController *sidebarController;
@property (nonatomic, strong) NSViewController *viewerController;

@property (nonatomic, strong) NSString *username;

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

- (void)initializeViewControllers
{
    NSLog(@"Woah!");

    StreamListViewModel *listViewModel = [[StreamListViewModel alloc] init];
    self.sidebarController = [[StreamListViewController alloc] initWithViewModel:listViewModel nibName:@"StreamListView" bundle:nil];
    [self setSidebarController:self.sidebarController];

    StreamViewModel *streamViewModel = [[StreamViewModel alloc] init];
    self.viewerController = [[StreamViewerViewController alloc] initWithViewModel:streamViewModel nibName:@"StreamViewer" bundle:nil];
    [self setViewerController:self.viewerController];
}

#pragma mark - Window Compositioning

- (void)setSidebarController:(NSViewController *)viewController
{
    if (_sidebarController == viewController) { return; }

    _sidebarController = viewController;
    [_sidebarController.view setFrame:_sidebarView.bounds];
    [_sidebarView addSubview:_sidebarController.view];
}

- (void)setViewerController:(NSViewController *)viewController
{
    if (_viewerController == viewController) { return; }

    _viewerController = viewController;
    [_viewerController.view setFrame:_viewer.bounds];
    [_viewer addSubview:_viewerController.view];
}

@end
