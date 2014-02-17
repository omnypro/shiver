//
//  StreamListViewItem.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "JAListViewItem.h"
#import "StreamViewModel.h"

@interface StreamListViewItem : JAListViewItem

@property (nonatomic, strong) StreamViewModel *object;

+ (StreamListViewItem *)initItem;
- (void)refreshLogo;
- (void)refreshPreview;

@end
