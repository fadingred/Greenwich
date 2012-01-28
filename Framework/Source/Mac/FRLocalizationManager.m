// 
// Copyright (c) 2012 FadingRed LLC
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

#import "FRLocalizationManager.h"
#import "FRLocalizationWindowController.h"
#import "FRExtraHelpController.h"
#import "FRBundleAdditions.h"
#import "FRTranslationContainer__.h"

@implementation FRLocalizationManager

+ (id)defaultLocalizationManager {
	static FRLocalizationManager *defaultLocalizationManager = nil;
	if (defaultLocalizationManager == nil) {
		@synchronized(self) {
			if (defaultLocalizationManager == nil) {
				defaultLocalizationManager = [[self alloc] init];
			}
		}
	}
	return defaultLocalizationManager;
}


#pragma mark -
#pragma mark extra help window
// ----------------------------------------------------------------------------------------------------
// extra help window
// ----------------------------------------------------------------------------------------------------

- (void)installExtraHelpMenu {
	NSString *appName = [[NSBundle mainBundle] name];
	NSString *title = [NSString stringWithFormat:FRLocalizedString(@"Translate %@", nil), appName];
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(showTranslatorWindow:) keyEquivalent:@""];
	[item setTarget:self];
	[[FRExtraHelpController defaultController] insertItem:item atIndex:0];
	[[FRExtraHelpController defaultController] install];
}


#pragma mark -
#pragma mark actions
// ----------------------------------------------------------------------------------------------------
// actions
// ----------------------------------------------------------------------------------------------------

- (IBAction)showTranslatorWindow:(id)sender {
	static FRLocalizationWindowController *controller = nil;
	if (!controller) {
		controller = [[FRLocalizationWindowController alloc] init];
		[controller addContainer:[FRTranslationContainer containerForApplicationBundle:[NSBundle mainBundle]]];
	}
	[controller showWindow:nil];
}	

@end
