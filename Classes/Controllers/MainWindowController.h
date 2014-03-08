//
//  MainWindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 2/7/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "SHWindowController.h"
#import "UserViewModel.h"

@class StreamListViewModel;
@class StreamListViewController;
@class StreamViewerViewController;
@class TitleView;

@interface MainWindowController : SHWindowController <NSWindowDelegate>

@property (nonatomic, strong) StreamListViewController *sidebarController;
@property (nonatomic, strong) StreamViewerViewController *viewerController;

@property (nonatomic, strong) StreamListViewModel *listViewModel;
@property (nonatomic, strong) UserViewModel *viewModel;

@property (weak) IBOutlet TitleView *titleView;
@property (weak) IBOutlet NSView *viewer;

@end
