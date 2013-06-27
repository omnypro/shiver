//
//  AboutWindowController.m
//  Shiver
//
//  Created by Bryan Veloso on 6/26/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "AboutView.h"
#import "NSColor+Hex.h"

#import "AboutWindowController.h"

@interface AboutWindowController () {
    IBOutlet NSTextField *_appTitleLabel;
    IBOutlet NSTextField *_versionAndBuildLabel;
    IBOutlet NSTextField *_designAndCodeLabel;
    IBOutlet NSTextField *_designAndCodeByLabel;
    IBOutlet NSButton *_designAndCodeByButton;
    IBOutlet NSTextField *_iconLabel;
    IBOutlet NSTextField *_iconByLabel;
    IBOutlet NSButton *_iconByButton;
    IBOutlet NSTextField *_copyrightLabel;
    IBOutlet NSTextField *_disclaimerLabel;
}

@property (weak) IBOutlet AboutView *view;

- (IBAction)designAndCodeRedirect:(id)sender;
- (IBAction)iconRedirect:(id)sender;

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

    NSColor *primaryGrayColor = [NSColor colorWithHex:@"#9B9B9B"];
    NSDictionary *colorDict = @{
        NSForegroundColorAttributeName: primaryGrayColor,
        NSBackgroundColorAttributeName: [NSColor clearColor],
    };

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
    NSAttributedString *designStr = [[NSAttributedString alloc] initWithString:[_designAndCodeByButton title] attributes:colorDict];
    [_designAndCodeByButton setAttributedTitle:designStr];

    [_iconLabel setTextColor:primaryGrayColor];
    [_iconByLabel setTextColor:[NSColor whiteColor]];
    NSAttributedString *iconStr = [[NSAttributedString alloc] initWithString:[_iconByButton title] attributes:colorDict];
    [_iconByButton setAttributedTitle:iconStr];

    [_copyrightLabel setTextColor:primaryGrayColor];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:[_disclaimerLabel stringValue]];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByWordWrapping];
    [style setMaximumLineHeight:12];
    [attrTitle addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, [attrTitle length])];
    [_disclaimerLabel setAttributedStringValue:attrTitle];
    [_versionAndBuildLabel setTextColor:[NSColor colorWithHex:@"#686868"]];

    // This needs to be invoked ... or else everything looks like shit.
    [self.view setNeedsDisplay:YES];
}

- (IBAction)designAndCodeRedirect:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://twitter.com/bryanveloso"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)iconRedirect:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://twitter.com/tobiasahlin"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
