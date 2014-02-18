//
//  MainWindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 2/7/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <RHPreferences/RHPreferences.h>

#import "SHWindowController.h"
#import "WindowViewModel.h"

@class StreamListViewController;
@class StreamViewerViewController;

@interface MainWindowController : SHWindowController <NSWindowDelegate>

@property (nonatomic, strong) StreamListViewController *sidebarController;
@property (nonatomic, strong) StreamViewerViewController *viewerController;
@property (nonatomic, strong, readonly) WindowViewModel *viewModel;
@property (nonatomic, strong, readonly) RHPreferencesWindowController *preferencesWindowController;

@property (weak) IBOutlet NSView *viewer;

@end
