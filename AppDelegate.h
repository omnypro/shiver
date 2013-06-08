//
//  AppDelegate.h
//  Shiver
//
//  Created by Bryan Veloso on 6/6/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *statusMenu;

@property (nonatomic, strong) NSStatusItem *statusBar;
@property (nonatomic, strong) NSPopover *popover;

@end
