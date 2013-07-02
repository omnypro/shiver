//
//  LoadingView.h
//  Shiver
//
//  Created by Bryan Veloso on 7/2/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoadingView : NSView

+ (id)init;
- (NSView *)loadingViewWithProgressIndicator;

@end
