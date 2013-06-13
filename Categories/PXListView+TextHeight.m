#import "PXListView+TextHeight.h"

@implementation PXListView (TextHeight)

- (CGFloat)heightForText:(NSString *)text
                    font:(NSFont *)font
     lineFragmentPadding:(float)lineFragmentPadding
       horizontalPadding:(float)horizontalPadding
          vertialPadding:(float)verticalPadding
               minHeight:(float)minHeight
{
    
    NSRect frame = [self frame];
	NSSize frameSize = NSMakeSize(NSWidth(frame), NSHeight(frame));
	BOOL hasVertScroller = NSHeight(frame) < _totalHeight;
	NSSize availableSize = [[self class] contentSizeForFrameSize:frameSize
										   hasHorizontalScroller:NO
											 hasVerticalScroller:hasVertScroller
													  borderType:[self borderType]];
	
	NSRect contentViewRect = NSMakeRect(0.0f, 0.0f, availableSize.width, availableSize.height);
    
    NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString:text] autorelease];
    NSTextContainer *textContainer = [[[NSTextContainer alloc]
    initWithContainerSize: NSMakeSize(NSWidth(contentViewRect) - horizontalPadding, FLT_MAX)] autorelease];
    NSLayoutManager *layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    [textStorage addAttribute:NSFontAttributeName 
                        value:font
                        range:NSMakeRange(0, [textStorage length])];
    [textContainer setLineFragmentPadding:lineFragmentPadding];
    (void) [layoutManager glyphRangeForTextContainer:textContainer];

    if([layoutManager usedRectForTextContainer:textContainer].size.height + verticalPadding < minHeight){
        return minHeight; 
    }   
    else{
        return ([layoutManager usedRectForTextContainer:textContainer].size.height + verticalPadding);
    }
}

@end
