//
//  EmptyErrorView.h
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "InnerShadowView.h"

@interface EmptyErrorView : InnerShadowView

+ (id)init;
- (NSView *)emptyViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle;
- (NSView *)errorViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle;

@end
