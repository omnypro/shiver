//
//  StreamListEmptyErrorView.m
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListBaseView.h"

#import "StreamListEmptyErrorView.h"

@implementation StreamListEmptyErrorView

+ (NSView *)errorViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle
{
    NSTextField *titleLabel = [[NSTextField alloc] init];
    titleLabel.stringValue = title;

    NSTextField *subTitleLabel = [[NSTextField alloc] init];
    subTitleLabel.stringValue = title;

    StreamListBaseView *view = [[StreamListBaseView alloc] initWithTitle:titleLabel subTitle:subTitleLabel image:nil];
    return view;
}

+ (void)makeTitleLabel:(NSTextField *)label
{

}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

@end
