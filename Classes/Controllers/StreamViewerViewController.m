//
//  StreamViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/14/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "StreamViewModel.h"

#import "StreamViewerViewController.h"

@implementation StreamViewerViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    [_webView setFrameLoadDelegate:self];

    [[RACObserve(self, viewModel) distinctUntilChanged] subscribeNext:^(StreamViewModel *stream) {
        [_webView setMainFrameURL:[stream.hlsURL absoluteString]];
    }];
}

#pragma mark - WebFrameLoadDelegate Methods

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
    return NO; // Prevent the selection of content.
}

@end
