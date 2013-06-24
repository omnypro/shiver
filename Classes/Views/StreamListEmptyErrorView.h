//
//  StreamListEmptyErrorView.h
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "StreamListBaseView.h"

@interface StreamListEmptyErrorView : NSObject

+ (NSView *)errorViewWithTitle:(NSString *)title subTitle:(NSString *)subTitle;

@end
