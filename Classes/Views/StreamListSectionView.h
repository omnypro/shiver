//
//  StreamListSectionView.h
//  Shiver
//
//  Created by Bryan Veloso on 2/23/14.
//  Copyright (c) 2014 Revyver, Inc. All rights reserved.
//

#import "JAListViewItem.h"

@interface StreamListSectionView : JAListViewItem

@property (weak) IBOutlet NSTextField *title;

+ (StreamListSectionView *)initItem;

@end
