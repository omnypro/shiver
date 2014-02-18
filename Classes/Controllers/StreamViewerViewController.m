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

@interface StreamViewerViewController () {
    IBOutlet NSTextField *_streamNameLabel;
}

@end

@implementation StreamViewerViewController

- (void)awakeFromNib
{
    [super awakeFromNib];

    [_webView setFrameLoadDelegate:self];
}

- (void)setSelectedStream:(StreamViewModel *)stream {
    NSURLRequest *request = [NSURLRequest requestWithURL:stream.hlsURL];
    [[_webView mainFrame] loadRequest:request];

    [_streamNameLabel setStringValue:stream.name];
}

#pragma mark - WebFrameLoadDelegate Methods

- (BOOL)webView:(WebView *)webView shouldChangeSelectedDOMRange:(DOMRange *)currentRange toDOMRange:(DOMRange *)proposedRange affinity:(NSSelectionAffinity)selectionAffinity stillSelecting:(BOOL)flag
{
    return NO; // Prevent the selection of content.
}

@end
