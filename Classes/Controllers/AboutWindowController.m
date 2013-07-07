//
//  AboutWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/26/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AboutView.h"
#import "HexColor.h"
#import "NSAttributedString+Hyperlink.h"

#import "AboutWindowController.h"

@interface AboutWindowController () {
    IBOutlet NSTextField *_appTitleLabel;
    IBOutlet NSTextField *_versionAndBuildLabel;
    IBOutlet NSTextField *_designAndCodeLabel;
    IBOutlet NSTextField *_designAndCodeByLabel;
    IBOutlet NSTextField *_designAndCodeByLink;
    IBOutlet NSTextField *_iconLabel;
    IBOutlet NSTextField *_iconByLabel;
    IBOutlet NSTextField *_iconByLink;
    IBOutlet NSTextField *_copyrightLabel;
    IBOutlet NSTextField *_disclaimerLabel;
}

@property (weak) IBOutlet AboutView *view;
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
    [[self window] setAllowsConcurrentViewDrawing:YES];

    NSColor *primaryGrayColor = [NSColor colorWithHexString:@"#9B9B9B" alpha:1];

    // Set up the colors and paragraph styles for all of the elements...
    // because I prefer to use hex values over Interface Builder's janky
    // color picker.
    [_appTitleLabel setTextColor:[NSColor whiteColor]];

    // Grab the version and build number and throw it into the panel.
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    [_versionAndBuildLabel setStringValue:[NSString stringWithFormat:@"Version %@ (build %@)", version, build]];
    [_versionAndBuildLabel setTextColor:primaryGrayColor];

    [_designAndCodeLabel setTextColor:primaryGrayColor];
    [_designAndCodeByLabel setTextColor:[NSColor whiteColor]];
    [_designAndCodeByLink setTextColor:primaryGrayColor];

    [_iconLabel setTextColor:primaryGrayColor];
    [_iconByLabel setTextColor:[NSColor whiteColor]];
    [_iconByLink setTextColor:primaryGrayColor];

    [_copyrightLabel setTextColor:primaryGrayColor];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:[_disclaimerLabel stringValue]];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:12];
    [attrTitle addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attrTitle length])];
    [_disclaimerLabel setAttributedStringValue:attrTitle];
    [_versionAndBuildLabel setTextColor:[NSColor colorWithHexString:@"#686868" alpha:1]];

    // This needs to be invoked ... or else everything looks like shit.
    [self.view setNeedsDisplay:YES];
}

@end
