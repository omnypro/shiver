//
//  SHWindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 2/13/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

@class RVMViewModel;

@interface SHWindowController : NSWindowController

@property (nonatomic, strong, readonly) RVMViewModel *viewModel;

- (id)initWithViewModel:(RVMViewModel *)viewModel;
- (id)initWithViewModel:(RVMViewModel *)viewModel nibName:(NSString *)nibName;

@end
