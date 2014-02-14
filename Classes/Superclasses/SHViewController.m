//
//  SHViewController.m
//  Shiver
//
//  Created by Bryan Veloso on 2/13/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "SHViewController.h"

@implementation SHViewController

- (id)initWithViewModel:(RVMViewModel *)viewModel
{
	return [self initWithViewModel:viewModel nibName:nil bundle:nil];
}

- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
    self = [super initWithNibName:nibName bundle:bundle];
    if (self == nil) return nil;

    _viewModel = viewModel;

    return self;
}

@end
