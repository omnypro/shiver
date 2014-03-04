//
//  StreamListSectionView.h
//  Shiver
//
//  Created by Bryan Veloso on 2/23/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "JAObjectListViewItem.h"

@interface StreamListSectionView : JAObjectListViewItem

@property (weak) IBOutlet NSTextField *title;

+ (StreamListSectionView *)initItem;

@end
