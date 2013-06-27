//
//  NSAttributedString+Hyperlink.h
//  Shiver
//
//  Created by Bryan Veloso on 6/27/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Hyperlink)
+(id)hyperlinkFromString:(NSString *)inString withURL:(NSURL *)aURL color:(NSColor *)color;
@end
