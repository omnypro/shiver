//
//  StreamViewController.h
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "SHViewController.h"

@class StreamListViewModel;
@class WebView;

@interface StreamViewerViewController : SHViewController

@property (weak) IBOutlet WebView *webView;

@end
