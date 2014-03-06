//
//  StreamListEmptyItemView.h
//  Shiver
//
//  Created by Bryan Veloso on 3/5/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "JAObjectListViewItem.h"

@interface StreamListEmptyItemView : JAObjectListViewItem

@property (nonatomic, weak) IBOutlet NSTextField *emptyLabel;

+ (StreamListEmptyItemView *)initItem;

@end
