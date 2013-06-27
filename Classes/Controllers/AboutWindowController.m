//
//  AboutWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/26/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AboutWindowController.h"

@interface AboutWindowController ()

@end

@implementation AboutWindowController

- (id)init
{
    self = [super init];
    if (self) { return [super initWithWindowNibName:@"AboutWindow"]; }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your
    // window controller's window has been loaded from its nib file.
}

@end
