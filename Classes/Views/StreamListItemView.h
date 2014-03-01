//
//  StreamListViewItem.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "JAListViewItem.h"

@class StreamViewModel;

@interface StreamListItemView : JAListViewItem {
    BOOL selected;
}

@property (nonatomic, strong) StreamViewModel *viewModel;

+ (StreamListItemView *)initItemStream:(StreamViewModel *)viewModel;

@end
