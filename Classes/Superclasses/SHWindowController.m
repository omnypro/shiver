//
//  SHWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/13/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "SHWindowController.h"

@implementation SHWindowController

- (id)initWithViewModel:(RVMViewModel *)viewModel
{
	return [self initWithViewModel:viewModel nibName:nil];
}

- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName
{
    self = [super initWithWindowNibName:nibName];
    if (self == nil) return nil;

    _viewModel = viewModel;
    DDLogInfo(@"hi!");

    return self;
}

@end
