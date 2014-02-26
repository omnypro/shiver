//
//  TitleView.h
//  Shiver
//
//  Created by Bryan Veloso on 2/21/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "RBLView.h"

@interface TitleView : RBLView

@property (nonatomic, assign) BOOL isActive;

@property (nonatomic, weak) IBOutlet NSTextField *gameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *viewersLabel;

@end
