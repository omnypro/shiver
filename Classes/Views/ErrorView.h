//
//  EmptyErrorView.h
//  Shiver
//
//  Created by Bryan Veloso on 6/24/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "RBLView.h"

@interface ErrorView : RBLView

@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, weak) IBOutlet NSTextField *titleLabel;
@property (nonatomic, weak) IBOutlet NSTextField *subTitleLabel;

@end
