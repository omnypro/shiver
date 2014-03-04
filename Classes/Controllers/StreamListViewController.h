//
//  StreamViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "JAObjectListView.h"
#import "SHViewController.h"
#import "StreamListViewModel.h"

@class StreamViewerViewController;

@interface StreamListViewController : SHViewController <NSUserNotificationCenterDelegate, JAListViewDelegate>

@property (nonatomic, strong, readonly) StreamListViewModel *viewModel;

@end
