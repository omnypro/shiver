//
//  StreamListViewItem.h
//  Shiver
//
//  Created by Bryan Veloso on 6/8/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "JAObjectListViewItem.h"

@class StreamViewModel;

@interface StreamListItemView : JAObjectListViewItem {
    BOOL selected;
}

@property (nonatomic, strong) StreamViewModel *viewModel;

+ (StreamListItemView *)initItemStream:(StreamViewModel *)viewModel;

@end
