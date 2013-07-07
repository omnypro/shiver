//
//  LoadingView.h
//  Shiver
//
//  Created by Bryan Veloso on 7/2/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "YRKSpinningProgressIndicator.h"

@interface LoadingView : NSView

@property (weak) IBOutlet YRKSpinningProgressIndicator *progressIndicator;

+ (id)init;
- (LoadingView *)loadingViewWithProgressIndicator;

@end
