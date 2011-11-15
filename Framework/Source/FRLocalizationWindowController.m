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

#include <sys/stat.h>

#import "FRLocalizationWindowController.h"
#import "FRUntranslatedCountCell.h"
#import "FRLocalizationBundleAdditions.h"
#import "FRLocalizationBundleAdditions__.h"
#import "FRTranslationInfo__.h"
#import "FRBundleAdditions.h"
#import "FRFileManagerArchivingAdditions.h"

static NSString * gSystemLanguage = nil;
static NSString * const kPathKey = @"path"; 
static NSString * const kDisplayNameKey = @"displayName"; 
static NSString * const kFileNameKey = @"fileName"; 
static NSString * const kBundleKey = @"bundleName"; 
static NSString * const FRLocalizationTypePreferenceKey = @"FRLocalizationType";
static void * const FRStringsFileCollectionDidChangeContext = @"FRStringsFileCollectionDidChangeContext";
static void * const FRStringsFileDidChangeContext = @"FRStringsFileDidChangeContext";
static void * const FRSelectedLanguageDidChangeContext = @"FRSelectedLanguageDidChangeContext";
static const NSTimeInterval kSaveTimeout = 0.5;
static const NSSize kTextContainerInset = { .width = 15, .height = 10 };

NSString * const FRLocalizationErrorDomain = @"FRLocalizationErrorDomain";

@interface FRLocalizationWindowController ()
- (void)loadStringsFiles;
- (void)loadTextView;
- (void)persistSelectedLanguage;
@end

@implementation FRLocalizationWindowController

+ (void)initialize {
	if (self == [FRLocalizationWindowController class]) {
		NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
		gSystemLanguage = ([languages count]) ? [languages objectAtIndex:0] : GREENWICH_DEFAULT_LANGUAGE;
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObjectsAndKeys:gSystemLanguage, FRLocalizationTypePreferenceKey, nil]];
	}
}


#pragma mark -
#pragma mark class helper methods
// ----------------------------------------------------------------------------------------------------
// class helper methods
// ----------------------------------------------------------------------------------------------------

+ (NSArray *)localizableBundles {
	static NSMutableArray *bundles = nil;
	if (bundles == nil) {
		bundles = [[NSMutableArray alloc] init];
		NSMutableArray *search = [NSMutableArray arrayWithObject:[NSBundle mainBundle]];
		
		void (^iterate_directory)(NSString *) = ^(NSString *directory) {
			NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
			for (NSString *path in contents) {
				NSBundle *bundle = [NSBundle bundleWithPath:[directory stringByAppendingPathComponent:path]];
				NSString *bundleID = [bundle objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
				if (bundleID) {
					[search addObject:bundle];
				}
			}
		};
		
		while ([search count]) {
			NSBundle *bundle = [search objectAtIndex:0];
			[bundles addObject:bundle];
			iterate_directory([bundle privateFrameworksPath]);
			iterate_directory([bundle builtInPlugInsPath]);
			[search removeObjectAtIndex:0];
		}
	}

	return bundles;
}

+ (NSArray *)translateBundlesForLanguage:(NSString *)language {
	NSArray *languages = [NSArray arrayWithObjects:language, nil];
	NSMutableArray *translatedBundles = [NSMutableArray array];
	
	for (NSBundle *bundle in [[self class] localizableBundles]) {
		NSBundle *translatedBundle = [NSBundle bundleForTranslationsWithIdentifier:[bundle bundleIdentifier]
													   updatingStringsForLanguages:languages error:NULL];
		if (translatedBundle) {
			[translatedBundles addObject:translatedBundle];
		}
	}
	
	return translatedBundles;
}


#pragma mark -
#pragma mark init/dealloc
// ----------------------------------------------------------------------------------------------------
// init/dealloc
// ----------------------------------------------------------------------------------------------------

- (id)init {
	if ((self = [super initWithWindowNibName:@"Localization"])) {
		// placeholder
	}
	return self;
}

- (void)dealloc {
	[stringsFiles setContent:nil];
	[stringsFiles removeObserver:self forKeyPath:@"arrangedObjects"];
	[saveTimer invalidate];
	[saveTimer release];
	[super dealloc];
}


#pragma mark -
#pragma mark loading
// ----------------------------------------------------------------------------------------------------
// loading
// ----------------------------------------------------------------------------------------------------

- (void)awakeFromNib {
	[[self window] center];
	[textView setFont:[NSFont fontWithName:@"Menlo" size:12]];
	[textView setTextContainerInset:kTextContainerInset];
	[tableView sizeLastColumnToFit];
	[tableView setSortDescriptors:
	 [NSArray arrayWithObject:
	  [[[NSSortDescriptor alloc] initWithKey:kDisplayNameKey ascending:YES] autorelease]]];
	
	NSKeyValueObservingOptions options =
		NSKeyValueObservingOptionNew |
		NSKeyValueObservingOptionOld |
		NSKeyValueObservingOptionInitial;
	[stringsFiles addObserver:self forKeyPath:@"arrangedObjects"
					  options:options context:FRStringsFileCollectionDidChangeContext];
	
	NSArray *lprojPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"lproj" inDirectory:nil];
	NSString *defaultLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:FRLocalizationTypePreferenceKey];
	
	for (NSString *path in lprojPaths) {
		NSString *language = [[path lastPathComponent] stringByDeletingPathExtension];
		if (![language isEqualToString:GREENWICH_DEFAULT_LANGUAGE]) {
			[languages addObject:language];
		}
	}
	if (![[languages arrangedObjects] containsObject:defaultLanguage]) {
		[languages addObject:defaultLanguage];
	}
	if (![[languages arrangedObjects] containsObject:gSystemLanguage]) {
		[languages addObject:gSystemLanguage];
	}

	[languages rearrangeObjects];
	[languages setSelectedObjects:
	 [NSArray arrayWithObjects:defaultLanguage, nil]];
	[languages addObserver:self forKeyPath:@"selectedObjects"
				   options:NSKeyValueObservingOptionInitial context:FRSelectedLanguageDidChangeContext];
}


#pragma mark -
#pragma mark observations
// ----------------------------------------------------------------------------------------------------
// observations
// ----------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	
	if (context == FRStringsFileCollectionDidChangeContext) {
		id removed = [change objectForKey:NSKeyValueChangeOldKey];
		id added = [change objectForKey:NSKeyValueChangeNewKey];
		if (removed == [NSNull null]) { removed = nil; }
		if (added == [NSNull null]) { added = nil; }
		[removed removeObserver:self
		   fromObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [removed count])]
					 forKeyPath:@"untranslatedCount"];
		[added addObserver:self
			 toObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [added count])]
					 forKeyPath:@"untranslatedCount"
						options:0
						context:FRStringsFileDidChangeContext];
	}
	else if (context == FRStringsFileDidChangeContext) {
		[tableView setNeedsDisplay];
	}
	else if (context == FRSelectedLanguageDidChangeContext) {
		[self loadStringsFiles];
		[self persistSelectedLanguage];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark -
#pragma mark helpers
// ----------------------------------------------------------------------------------------------------
// helpers
// ----------------------------------------------------------------------------------------------------

- (void)saveSelectedStringsFile {
	FRTranslationInfo *info = [[stringsFiles selectedObjects] lastObject];
	NSString *path = info.path;
	NSError *error = nil;
	BOOL written = [[textView string] writeToFile:path atomically:YES encoding:NSUTF16StringEncoding error:&error];
	if (!written) {
		[[self window] presentError:error];
	}
	
}

- (void)loadStringsFiles {
	NSString *language = [[languages selectedObjects] lastObject];
	NSArray *translateBundles = [[self class] translateBundlesForLanguage:language];
	NSMutableArray *content = [NSMutableArray array];
	
	for (NSBundle *bundle in translateBundles) {
		NSError *error = nil;
		NSArray *paths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[bundle bundlePath] error:&error];
		if (paths) {
			for (NSString *path in paths) {
				NSString *directoryPath = [path stringByDeletingLastPathComponent];
				NSString *directoryName = [[directoryPath lastPathComponent] stringByDeletingPathExtension];
				NSString *fileExtension = [path pathExtension];
				if ([directoryName isEqualToString:language] && [fileExtension isEqualToString:@"strings"]) {
					NSString *infoPath = [[bundle bundlePath] stringByAppendingPathComponent:path];
					FRTranslationInfo *info = [FRTranslationInfo infoWithLanguage:language path:infoPath];
					if (![[info bundleName] isEqualToString:@"Sparkle"]) {
						[content addObject:info];
					}
				}
			}
		}
		else { [NSApp presentError:error]; }
	}
	
	[stringsFiles setContent:content];
	[self loadTextView];
}

- (void)loadTextView {
	FRTranslationInfo *info = [[stringsFiles selectedObjects] lastObject];
	NSString *path = info.path;
	NSError *error = nil;
	NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF16StringEncoding error:&error];
	if (!contents) {
		[[self window] presentError:error];
		contents = @"";
	}
	[textView setString:contents];
}

- (void)persistSelectedLanguage {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *language = [[languages selectedObjects] lastObject];
	[defaults setObject:language forKey:FRLocalizationTypePreferenceKey];
}


#pragma mark -
#pragma mark actions
// ----------------------------------------------------------------------------------------------------
// actions
// ----------------------------------------------------------------------------------------------------

- (void)saveDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	void (^completion)(NSInteger) = contextInfo;
	completion(returnCode);
	[completion release];
}

- (IBAction)packageStringsFiles:(id)sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setTitle:FRLocalizedString(@"Save Location", nil)];
	[panel setMessage:FRLocalizedString(@"Please choose a location to save your translation package", nil)];
	[panel setPrompt:FRLocalizedString(@"Save", nil)];
	[panel setExtensionHidden:TRUE];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:@"tbz"]];

	void (^completion)(NSInteger) = ^(NSInteger returnCode) {
		if (returnCode == NSFileHandlingPanelOKButton) {
			NSError *error = nil;
			NSFileManager *fileManager = [NSFileManager defaultManager];
			char *tmpname = NULL;
			asprintf(&tmpname, "%s/translation.XXXXXX", [NSTemporaryDirectory() UTF8String]);
			mktemp(tmpname);
			NSString *temp = [[NSString stringWithUTF8String:tmpname] stringByAppendingPathComponent:
							  [[NSBundle mainBundle] name]];
			free(tmpname);

			// make the folder that the strings files will be packaged into
			if (![fileManager createDirectoryAtPath:temp
						withIntermediateDirectories:YES
										 attributes:nil
											  error:&error]) {
				NSLog(@"Problem creating destination folder with error: %@", error);
			}
			
			// copy strings files to the folder that will be packaged
			for (FRTranslationInfo *info in [stringsFiles arrangedObjects]) {
				NSString *path = info.path;
				NSString *bundle = info.bundleName;
				NSString *fileName = info.fileName;
				if (![bundle length]) { bundle = [[NSBundle mainBundle] name]; }
				NSString *destinationDirectory = [temp stringByAppendingPathComponent:bundle];
				NSString *destinationPath = [destinationDirectory stringByAppendingPathComponent:fileName];
				BOOL result =
					[fileManager createDirectoryAtPath:destinationDirectory
						   withIntermediateDirectories:YES
											attributes:nil
												 error:&error] &&
					[fileManager copyItemAtPath:path
										 toPath:destinationPath
										  error:&error];
				if (!result) {
					NSLog(@"Problem copying strings files with error: %@", error);
				}
			}
			
			// package the folder into a .tbz for emailing
			NSString *archiveDestination = [[panel URL] path];
			[fileManager removeItemAtPath:archiveDestination error:NULL];
#ifdef REDCORE_LEOPARD_BASE
			BOOL result = [fileManager compressFileAtPath:temp to:archiveDestination error:&error];
#else
			BOOL result = [fileManager compressItemAtPath:temp to:archiveDestination error:&error];
#endif
			if (!result) {
				NSLog(@"Problem archiving strings files package with error: %@", error);
			} else {
				if (![fileManager removeItemAtPath:temp error:&error]) {
					NSLog(@"Problem removing file package temp directory with error: %@", error);
				}
			}
		}
	};

    // the desktop is available through expanding ~ whether using sandboxing or not.
    // with sandboxing, it's available through the application's container.
#if REDCORE_LEOPARD_BASE
	[panel beginSheetForDirectory:[@"~/Desktop" stringByExpandingTildeInPath]
							 file:@"translation"
				   modalForWindow:[self window]
					modalDelegate:self
				   didEndSelector:@selector(saveDidEnd:returnCode:contextInfo:)
					  contextInfo:[completion copy]];
#else
	[panel setDirectoryURL:[NSURL URLWithString:[@"~/Desktop" stringByExpandingTildeInPath]]];
	[panel setNameFieldStringValue:@"translation"];
	[panel beginSheetModalForWindow:[self window]
				  completionHandler:completion];
#endif
}


#pragma mark -
#pragma mark tableView delegate
// ----------------------------------------------------------------------------------------------------
// tableView delegate
// ----------------------------------------------------------------------------------------------------

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row {
	if ([[aTableColumn identifier] isEqualToString:@"index"]) {
		return [NSString stringWithFormat:@"%i", row + 1];
	} else {
		return nil;
	}
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)col row:(NSInteger)row {
	if ([cell isKindOfClass:[FRUntranslatedCountCell class]]) {
		id object = [[stringsFiles arrangedObjects] objectAtIndex:row];
		if ([object respondsToSelector:@selector(untranslatedCount)]) {
			[cell setUntranslated:[object untranslatedCount]];
		}
		else { [cell setUntranslated:0]; }
	}
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	[self saveSelectedStringsFile];
	return TRUE;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self loadTextView];
}


#pragma mark -
#pragma mark text delegate
// ----------------------------------------------------------------------------------------------------
// text delegate
// ----------------------------------------------------------------------------------------------------

- (void)textDidChange:(NSNotification *)aNotification {
	[saveTimer invalidate];
	[saveTimer release];
	saveTimer = [[NSTimer scheduledTimerWithTimeInterval:kSaveTimeout
												  target:self selector:@selector(saveSelectedStringsFile)
												userInfo:nil repeats:NO] retain];
}

@end
