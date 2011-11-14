// 
// Copyright (c) 2011 FadingRed LLC
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 

#import "FRUntranslatedCountCell.h"

#define UNTRANSLATED_CIRCLE_PADDING		3
#define UNTRANSLATED_CIRCLE_MINWIDTH	24
#define UNTRANSLATED_TEXT_PADDING		12
#define UNTRANSLATED_TEXT_SHRINK		2

#define UNTRANSLATED_STANDARD_COLOR		([NSColor colorWithCalibratedRed:0.60 green:0.66 blue:0.78 alpha:1.00])
#define UNTRANSLATED_INACTIVE_COLOR		([NSColor colorWithCalibratedRed:0.67 green:0.67 blue:0.67 alpha:1.00])
#define UNTRANSLATED_HIGHLIGHT_COLOR	([NSColor whiteColor])

static const CGFloat kInactiveOpacity = 0.6;


@implementation FRUntranslatedCountCell

@synthesize untranslated;

- (NSAttributedString *)untranslatedAttributedString {
	if (untranslated) {
		NSColor *color = nil;
		if ([self interiorBackgroundStyle] == NSBackgroundStyleLowered ||
			[self interiorBackgroundStyle] == NSBackgroundStyleDark) {
			if (![[[self controlView] window] isKeyWindow]) { color = UNTRANSLATED_INACTIVE_COLOR; }
			else { color = UNTRANSLATED_STANDARD_COLOR; }
		}
		else { color = UNTRANSLATED_HIGHLIGHT_COLOR; }
		
		NSFont *font = [NSFont fontWithName:@"Helvetica-Bold" size:[[self font] pointSize] - UNTRANSLATED_TEXT_SHRINK];
		NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setAlignment:NSCenterTextAlignment];
		
		NSString *string = [NSString stringWithFormat:@"%i", untranslated];
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									font, NSFontAttributeName,
									color, NSForegroundColorAttributeName,
									style, NSParagraphStyleAttributeName, nil];
		
		return [[[NSAttributedString alloc] initWithString:string
												attributes:attributes] autorelease];
	}
	else { return nil; }
}

- (NSRect)untranslatedRectForString:(NSAttributedString *)string frame:(NSRectPointer)cellFrame {
	if (untranslated) {
		float width = [string size].width + UNTRANSLATED_TEXT_PADDING * 2;
		if (width < UNTRANSLATED_CIRCLE_MINWIDTH) { width = UNTRANSLATED_CIRCLE_MINWIDTH; }
		
		NSRect rect;
		NSDivideRect(*cellFrame, &rect, cellFrame, width, NSMaxXEdge);
		return NSInsetRect(rect, UNTRANSLATED_CIRCLE_PADDING, UNTRANSLATED_CIRCLE_PADDING);
	} else { return NSZeroRect; }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	
	if (untranslated) {
		NSAttributedString *string = [self untranslatedAttributedString];
		NSRect rect = [self untranslatedRectForString:string frame:&cellFrame];
		
		NSColor *color = nil;
		if ([self interiorBackgroundStyle] == NSBackgroundStyleLowered ||
			[self interiorBackgroundStyle] == NSBackgroundStyleDark) { color = UNTRANSLATED_HIGHLIGHT_COLOR; }
		else if (![[controlView window] isKeyWindow]) { color = UNTRANSLATED_INACTIVE_COLOR; }
		else { color = UNTRANSLATED_STANDARD_COLOR; }
		
		[color set];
		[[NSBezierPath bezierPathWithRoundedRect:rect
										 xRadius:rect.size.height/2.0
										 yRadius:rect.size.width] fill];
		
		NSRect stringRect = rect;
		stringRect.size = NSMakeSize(rect.size.width, [string size].height);
		stringRect.origin.x += (rect.size.height - stringRect.size.height) / 2.0;
		stringRect.origin.y += (rect.size.width - stringRect.size.width) / 2.0;
		[string drawInRect:stringRect];
	}
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
