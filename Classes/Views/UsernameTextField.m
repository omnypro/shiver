//
//  UsernameTextField.m
//  Shiver
//
//  Created by Bryan Veloso on 6/19/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "UsernameTextField.h"

# import "User.h"

@implementation UsernameTextField

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [User userWithBlock:^(User *user, NSError *error) {
        if (user) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitch.tv/%@", user.name]];
            [[NSWorkspace sharedWorkspace] openURL:url];
        }
    }];
}

@end
