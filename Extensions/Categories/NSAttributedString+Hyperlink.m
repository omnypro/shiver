//
//  NSAttributedString+Hyperlink.m
//  Shiver
//
//  Created by Bryan Veloso on 6/27/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSAttributedString+Hyperlink.h"

@implementation NSAttributedString (Hyperlink)

+(id)hyperlinkFromString:(NSString *)inString withURL:(NSURL *)aURL color:(NSColor *)color
{
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:inString];
    NSRange range = NSMakeRange(0, [attrString length]);

    [attrString beginEditing];
    [attrString addAttribute:NSLinkAttributeName value:[aURL absoluteString] range:range];
    [attrString addAttribute:NSForegroundColorAttributeName value:color range:range];
    [attrString endEditing];

    return attrString;
}

@end