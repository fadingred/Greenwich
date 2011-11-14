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

#import "FRLocalizationManager.h"
#import "FRLocalizationPickerWindowController.h"

NSString *FRLocalizationTypePreferenceKey = @"FRLocalizationType";

@interface FRLocalizationPickerWindowController (Private)
- (id)dataSource;
@end

@implementation FRLocalizationPickerWindowController

+ (void)initialize {
	if (self == [FRLocalizationManager class]) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																 @"", FRLocalizationTypePreferenceKey, nil]];
	}
}

@synthesize selectedLanguage;

- (id)init {
	if ((self = [super initWithWindowNibName:@"LocalizationPicker"])) {
		// placeholder
	}
	return self;
}

- (void)awakeFromNib {
	[[self window] center];
	NSArray * lprojPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"lproj" inDirectory:nil];
	
	for (NSString *path in lprojPaths) {
		[languages addObject:[[path lastPathComponent] stringByDeletingPathExtension]];
	}
	[languages rearrangeObjects];
	
	[languages setSelectedObjects:
	 [NSArray arrayWithObjects:
	  [[NSUserDefaults standardUserDefaults] objectForKey:FRLocalizationTypePreferenceKey], nil]];
}

- (IBAction)setLanguage:(id)sender {
	[self setSelectedLanguage:[[languages selectedObjects] lastObject]];
	[[NSUserDefaults standardUserDefaults] setObject:[self selectedLanguage] forKey:FRLocalizationTypePreferenceKey];
	[NSApp stopModalWithCode:NSAlertDefaultReturn];
	[self close];
}

- (IBAction)cancel:(id)sender {
	[NSApp stopModalWithCode:NSAlertErrorReturn];
	[self close];
}

@end
