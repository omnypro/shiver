//
//  ApplicationController.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "ShiverApplication.h"

#import <Cocoa/Cocoa.h>

@class WindowController;

@interface ApplicationController : NSObject <ShiverApplicationDelegate> {}

@property (nonatomic, readonly, strong) WindowController *windowController;

+ (ApplicationController *)sharedInstance;

@end
