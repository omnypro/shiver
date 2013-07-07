//
//  StatusItemView.m
//  Shiver
//
//  Created by Bryan Veloso on 7/5/13.
//  Copyright (c) 2013 Revyver, Inc. All rights reserved.
//

#import "NSWindow+SHExtensions.h"

#import "StatusItemView.h"

@interface StatusItemView ()
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSImageView *imageView;
@property (nonatomic, strong) NSTextField *textField;
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSWindow *mainWindow;
@end

@implementation StatusItemView

- (id)initWithWindow:(NSWindow *)window image:(NSImage *)image alternateImage:(NSImage *)alternateImage label:(NSString *)label
{
    self.height = [[NSStatusBar systemStatusBar] thickness];
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        self.mainWindow =  window;
        [self.mainWindow setDelegate:self];

        self.image = image;
        self.alternateImage = alternateImage;

        _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(4, 1, 23, self.height)];
        [self addSubview:self.imageView];

        _textField = [[NSTextField alloc] initWithFrame:NSMakeRect(26, 3, 0, self.height)];
        [_textField setFont:[NSFont menuBarFontOfSize:0]];
        [_textField setBordered:NO];
        [_textField setDrawsBackground:NO];
        [_textField setSelectable:NO];
        if (label) { [_textField setStringValue:label]; }
        [self addSubview:_textField];

        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
        _statusItem.view = self;

        _active = NO;
    }

    [self updateViewFrame];
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self.statusItem drawStatusBarBackgroundInRect:dirtyRect withHighlight:_active];

    if (_active) {
        [_textField setTextColor:[NSColor selectedMenuItemTextColor]];
    }
    else {
        [_textField setTextColor:[NSColor blackColor]];
    }

    NSImage *image = (_active ? _alternateImage : _image);
    _imageView.image = image;
}

- (void)updateViewFrame
{
    CGFloat width = 0;
    if ([_textField.stringValue isEqualToString:@""]) {
        width = MAX(self.alternateImage.size.width, self.image.size.width) + 8;
    }
    else {
        [_textField sizeToFit];
        width = MAX(self.alternateImage.size.width, self.image.size.width) + [_textField frame].size.width + 8;
    }

    NSRect frame = NSMakeRect(0, 0, width, self.height);
    self.frame = frame;

    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if ([self.mainWindow isVisible]) { [self hideWindow]; }
    else { [self showWindow]; }

    [super mouseDown:theEvent];
}

#pragma mark - Window Visibility Methods

- (void)hideWindow
{
    self.active = NO;
    [self.mainWindow fadeOut:nil];
}

- (void)showWindow
{
    self.active = YES;

    NSRect statusItemRect = [self.window frame];
    CGFloat midX = NSMidX(statusItemRect);
    CGFloat windowWidth = NSWidth([self.mainWindow frame]);
    CGFloat windowHeight = NSHeight([self.mainWindow frame]);

    NSRect windowFrame = NSMakeRect(
        floor(midX - (windowWidth / 2.0)),
        floor(NSMaxY(statusItemRect) - windowHeight - [[NSApp mainMenu] menuBarHeight] - 10),
        windowWidth, windowHeight);
    [self.mainWindow setFrameOrigin:windowFrame.origin];
    [self.mainWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title
{
	[_textField setStringValue:title];
	[self updateViewFrame];
}

- (void)setActive:(BOOL)active
{
    _active = active;
    [self setNeedsDisplay:YES];
}

- (void)setAlternateImage:(NSImage *)image
{
    _alternateImage = image;
    if (!image && _image) {
        _alternateImage = _image;
    }
    [self updateViewFrame];
}

- (void)setImage:(NSImage *)image
{
    _image = image;
    [self updateViewFrame];
}

#pragma - NSWindowDelegate Methods

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    self.active = YES;
    DDLogVerbose(@"Application (%@): Displaying main window.", [self class]);
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    self.active = NO;
    DDLogVerbose(@"Application (%@): Hiding main window.", [self class]);
}

- (void)windowWillClose:(NSNotification *)notification
{
    self.active = NO;
    DDLogVerbose(@"Application (%@): Closing main window.", [self class]);
}

@end
