//
//  ShiverApplication.h
//  Shiver
//
//  Created by Bryan Veloso on 6/6/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

@protocol ShiverApplicationDelegate <NSApplicationDelegate>

@end

@interface ShiverApplication : NSApplication

@property (nonatomic, unsafe_unretained) id <ShiverApplicationDelegate> delegate;

@end
