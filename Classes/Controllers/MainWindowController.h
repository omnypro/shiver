//
//  MainWindowController.h
//  Shiver
//
//  Created by Bryan Veloso on 2/7/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import <RHPreferences/RHPreferences.h>

#import "WindowViewModel.h"

#import "SHWindowController.h"

@interface MainWindowController : SHWindowController <NSWindowDelegate>

@property (nonatomic, strong, readonly) WindowViewModel *viewModel;
@property (nonatomic, strong, readonly) RHPreferencesWindowController *preferencesWindowController;

@end
