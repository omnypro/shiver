#import <Cocoa/Cocoa.h>
#import "PXListView.h"

@interface PXListView (TextHeight)

/*
    return [view heightForText:text 
                          font:[NSFont fontWithName:@"Lucida Grande" size:12.0] 
           lineFragmentPadding:5.0
             horizontalPadding:60.0
                vertialPadding:30.0
                     minHeight:60.0];
*/

- (CGFloat)heightForText:(NSString *)text
                    font:(NSFont *)font
     lineFragmentPadding:(float)lineFragmentPadding
       horizontalPadding:(float)horizontalPadding
          vertialPadding:(float)verticalPadding
               minHeight:(float)minHeight;

@end
