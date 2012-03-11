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

#import "FRLocalizationBundleAdditions.h"
#import "FRLocalizationBundleAdditions__.h"
#import "FRBundleAdditions.h"
#import "FRRuntimeAdditions.h"
#import "FRStrings.h"

@interface NSBundle (FRLocalizationBundleAdditionsPrivate)
+ (BOOL)_mergeContentsOfStringsFile:(NSString *)mergeFromPath
			  intoStringsFileAtPath:(NSString *)mergeIntoPath
							  error:(NSError **)error;
@end

static BOOL FRShouldPseudoLocalize(void);
static NSString *FRPseudoLocalizedString(NSString *string);

// swizzling
static NSString *(*SLocalizedStringLookup)(id self, SEL _cmd, NSString *key, NSString *value, NSString *table);
static NSString *(FRLocalizedStringLookup)(id self, SEL _cmd, NSString *key, NSString *value, NSString *table);

@implementation NSBundle (FRLocalizationBundleAdditions)

+ (void)load {
	[self swizzle:@selector(localizedStringForKey:value:table:)
			 with:(IMP)FRLocalizedStringLookup store:(IMPPointer)&SLocalizedStringLookup];
}


#pragma mark -
#pragma mark localization
// ----------------------------------------------------------------------------------------------------
// localization
// ----------------------------------------------------------------------------------------------------

static NSString *FRLocalizedStringLookup(id self, SEL _cmd, NSString *key, NSString *value, NSString *table) {
	NSBundle *bundle = self;
	NSString *bundleID = [self bundleIdentifier];
	BOOL shouldPseudoLocalize = FALSE;
	
	if (bundleID) {
		// grab the translated bundle and ensure that it contains an lproj folder for the language the user has set in
		// their system preferences. if it's not, we want to just fall back to the standard lookup. this allows fluent
		// second language speakers to translate the app (and relaunch to see their changes with their system
		// preferences are changed), but allows them to switch back to their native language without greenwhich always
		// loading what they translated.
		NSBundle *translated = [[self class] bundleForTranslationsWithIdentifier:bundleID];
		NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
		NSString *systemLanguage = ([languages count]) ? [languages objectAtIndex:0] : GREENWICH_DEFAULT_LANGUAGE;
		NSString *lprojName = [NSString stringWithFormat:@"%@.lproj", systemLanguage];
		NSString *lprojDirectory = [[translated bundlePath] stringByAppendingPathComponent:lprojName];
		NSFileManager *manager = [NSFileManager defaultManager];
		if (translated && [manager fileExistsAtPath:lprojDirectory]) {
			bundle = translated;
			shouldPseudoLocalize = FRShouldPseudoLocalize();
		}
		else {
			// we should pseudo localize for anything that's a resource in the main bundle.
			// items outside the main bundle are things like system frameworks, and it doesn't
			// really make sense to pseudo localize those.
			shouldPseudoLocalize = FRShouldPseudoLocalize() &&
				[[self bundlePath] hasPrefix:[[NSBundle mainBundle] bundlePath]];
		}
	}
	
	NSString *result = SLocalizedStringLookup(bundle, _cmd, key, value, table);
	if (result && shouldPseudoLocalize) {
		result = FRPseudoLocalizedString(result);
	}
	return result;
}

static BOOL FRShouldPseudoLocalize(void) {
	static BOOL should = FALSE;
	static BOOL checked = FALSE;
	static NSString * const kSynchronize = @"FRLocalizationBundleAdditionsSynchronizationSymbol";
	if (!checked) {
		@synchronized(kSynchronize) {
			if (!checked) {
				NSArray *languages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
				NSDictionary *environment = [[NSProcessInfo processInfo] environment];
				checked = TRUE;
				should =
					([languages count] && [[languages objectAtIndex:0] isEqualToString:GREENWICH_DEFAULT_LANGUAGE]) &&
					([environment objectForKey:@"GREENWICH_PSEUDO_LOCALIZE"] != nil);
			}
		}
	}
	return should;
}

static NSString *FRPseudoLocalizedString(NSString *string) {
	NSMutableString *alter = [string mutableCopy];
	
	// make the string at least 33% longer to simulate wordier languages
	NSUInteger desiredLength = [alter length] * 4 / 3;
	NSArray *words =
		[NSArray arrayWithObjects:
		 @"lorem", @"ipsum", @"dolor", @"sit", @"amet", @"consectetur", @"adipiscing", @"elit", @"vestibulum",
		 @"vulputate", @"pulvinar", @"erat", @"ed", @"venenatis", @"ipsum", @"vel", @"urna", @"porta", @"ac",
		 @"pellentesque", @"nunc", @"placerat", @"vivamus", @"pretium", @"convallis", @"arcu", @"in", @"ornare",
		 @"aliquam", @"erat", @"volutpat", @"in", @"viverra", @"sollicitudin", @"nisl", @"malesuada", @"rhoncus",
		 @"tortor", @"fermentum", @"in", @"nulla", @"vehicula", @"elit", @"vitae", @"mi", @"tristique", @"laoreet",
		 @"eget", @"eu", @"lacus", @"integer", @"varius", @"enim", @"sed", @"nisi", @"porta", @"ornare", @"sed",
		 @"aliquet", @"urna", @"et", @"sapien", @"tristique", @"pharetra", @"mauris", @"non", @"ipsum", @"velit",
		 @"vel", @"consectetur", @"quam", @"vivamus", @"a", @"sem", @"vitae", @"orci", @"pharetra", @"mattis",
		 @"adipiscing", @"dignissim", @"massa", @"sed", @"vulputate", @"lobortis", @"orci", @"in", @"vehicula",
		 @"nunc", @"mattis", @"sed", @"mauris", @"molestie", @"purus", @"id", @"leo", @"sollicitudin", @"tincidunt",
		 @"proin", @"pulvinar", @"tincidunt", @"mattis", @"fusce", @"quis", @"sapien", @"eu", @"nisl", @"porta",
		 @"lacinia", @"vitae", @"a", @"lacus", @"phasellus", @"congue", @"congue", @"euismod", @"donec", @"euismod",
		 @"leo", @"non", @"molestie", @"adipiscing", @"nibh", @"ante", @"cursus", @"odio", @"eu", @"gravida", @"dui",
		 @"libero", @"id", @"eros", @"ut", @"egestas", @"lectus", @"non", @"dolor", @"euismod", @"et", @"malesuada",
		 @"nunc", @"mollis", @"pellentesque", @"vel", @"mi", @"urna", @"vestibulum", @"eu", @"libero", @"id", @"felis",
		 @"faucibus", @"gravida", @"etiam", @"sapien", @"quam", @"mollis", @"et", @"pulvinar", @"et", @"auctor",
		 @"ut", @"augue", @"cras", @"a", @"scelerisque", @"eros", @"proin", @"felis", @"purus", @"ullamcorper", @"eu",
		 @"pellentesque", @"a", @"luctus", @"vel", @"nunc", @"sed", @"id", @"justo", @"a", @"lorem", @"ultricies",
		 @"vulputate", @"sed", @"rhoncus", @"bibendum", @"justo", @"vel", @"consequat", @"augue", @"aliquam", @"non",
		 @"donec", @"sollicitudin", @"mauris", @"et", @"justo", @"ullamcorper", @"tempor", @"fusce", @"molestie",
		 @"lacus", @"ut", @"bibendum", @"suscipit", @"lorem", @"ipsum", @"interdum", @"nulla", @"et", @"hendrerit",
		 @"odio", @"arcu", @"vel", @"arcu", @"lorem", @"ipsum", @"dolor", @"sit", @"amet", @"consectetur",
		 @"adipiscing", @"elit", @"fusce", @"et", @"feugiat", @"ligula", nil];
	
	while ([alter length] < desiredLength) {
		[alter appendFormat:@" %@", [words objectAtIndex:random() % [words count]]];
	}
	

	__block NSUInteger choice = 0;
	void (^doReplacement)(NSString *, NSArray *) = ^(NSString *search, NSArray *replacements) {
		NSRange searchRange;
		NSRange matchRange;
		searchRange = NSMakeRange(0, [alter length]);
		while ((matchRange = [alter rangeOfString:search options:0 range:searchRange]).location != NSNotFound) {
			NSString *replacement = [replacements objectAtIndex:choice % [replacements count]];
			[alter replaceCharactersInRange:matchRange withString:replacement];
			searchRange.location = matchRange.location + [replacement length];
			searchRange.length = [alter length] - searchRange.location;
			choice += 1;
		}
	};
	
	doReplacement(@"a", [NSArray arrayWithObjects:@"a", @"å", @"a", @"ä", @"a", @"â", @"a", @"à", @"á", @"a", nil]);
	doReplacement(@"e", [NSArray arrayWithObjects:@"e", @"é", @"e", @"è", @"e", @"e", @"ê", @"e", @"ë", @"e", nil]);
	doReplacement(@"i", [NSArray arrayWithObjects:@"i", @"î", @"i", @"i", @"i", @"ì", @"i", @"í", @"i", @"i", nil]);
	doReplacement(@"o", [NSArray arrayWithObjects:@"o", @"ö", @"o", @"ø", @"o", @"ô", @"ò", @"o", @"ó", @"o", nil]);
	doReplacement(@"u", [NSArray arrayWithObjects:@"u", @"ü", @"u", @"û", @"u", @"ú", @"u", @"u", @"ù", @"u", nil]);
	doReplacement(@"n", [NSArray arrayWithObjects:@"ñ", @"n", @"n", @"n", @"n", @"n", @"n", @"n", @"n", @"n", nil]);
	doReplacement(@"ae", [NSArray arrayWithObjects:@"æ", @"ae", @"ae", @"ae", @"ae", @"ae", @"ae", @"ae", @"ae", nil]);
	doReplacement(@"ss", [NSArray arrayWithObjects:@"ß", @"ss", @"ss", @"ss", @"ss", @"ss", @"ss", @"ss", @"ss", nil]);
	
	return alter;
}


#pragma mark -
#pragma mark translation lookup/creation
// ----------------------------------------------------------------------------------------------------
// translation lookup/creation
// ----------------------------------------------------------------------------------------------------

+ (NSString *)translactionStoragePath {
	return [[[self mainBundle] applicationSupportDirectory] stringByAppendingPathComponent:@"Translations"];
}

+ (id)bundleForTranslationsWithIdentifier:(NSString *)identifier {
	NSBundle *original = [self bundleWithIdentifier:identifier loaded:NULL];
	return [original bundleUsingContentsForTranslationsWithIdentifier:identifier
										  updatingStringsForLanguages:nil
																error:NULL];
}

- (id)bundleUsingContentsForTranslationsWithIdentifier:(NSString *)bundleIdentifier
						   updatingStringsForLanguages:(NSArray *)languages
												 error:(NSError **)error {

	BOOL create = [languages count];
	NSFileManager *manager = [NSFileManager defaultManager];

	NSBundle *originalBundle = self;
	NSBundle *translateBundle = nil;
	NSString *translateBundlePath = nil;
	
	if (originalBundle) {
		NSString *translationsPath = [[self class] translactionStoragePath];
		translateBundlePath = [translationsPath stringByAppendingPathComponent:bundleIdentifier];
		
		if (create) {
			[manager createDirectoryAtPath:translateBundlePath withIntermediateDirectories:YES
								attributes:nil error:NULL];
		}
		
		translateBundle = [NSBundle bundleWithPath:translateBundlePath];
	}

	if (translateBundle && create) {
		NSString *resourcesPath = [originalBundle resourcePath];
		// using an enumerator because subpathsOfDirectoryAtPath doesn't traverse the path
		// if it's a symbolic link (even though it's documented to traverse it)
		NSEnumerator *enumerator = [manager enumeratorAtPath:resourcesPath];
		NSArray *paths = [enumerator allObjects];
		for (NSString *path in paths) {
			if (translateBundle == nil) { break; }
			NSString *directoryPath = [path stringByDeletingLastPathComponent];
			NSString *directoryName = [[directoryPath lastPathComponent] stringByDeletingPathExtension];
			NSString *fileExtension = [path pathExtension];
			if ([languages containsObject:directoryName] && [fileExtension isEqualToString:@"strings"]) {
				NSString *originalPath = [resourcesPath stringByAppendingPathComponent:path];
				NSString *translatePath = [translateBundlePath stringByAppendingPathComponent:path];
				
				if ([manager fileExistsAtPath:translatePath]) {
					if (![[self class] _mergeContentsOfStringsFile:originalPath // merge in progress translations
									 intoStringsFileAtPath:translatePath error:error]) {
						translateBundle = nil;
					}
				}
				else {
					if ([manager createDirectoryAtPath:[translatePath stringByDeletingLastPathComponent]
						   withIntermediateDirectories:YES attributes:nil error:error]) {
						if (![manager copyItemAtPath:originalPath toPath:translatePath error:error]) {
							translateBundle = nil;
						}
					}
					else { translateBundle = nil; }
				}
			}
		}
		
		// check to see if any files need to be created from the default language version
		for (NSString *path in paths) {
			if (translateBundle == nil) { break; }
			NSString *fileComponent = [path lastPathComponent];
			NSString *directoryPath = [path stringByDeletingLastPathComponent];
			NSString *directoryComponent = [directoryPath lastPathComponent];
			NSString *basePath = [directoryPath stringByDeletingLastPathComponent];
			NSString *directoryExtension = [directoryComponent pathExtension];
			NSString *directoryName = [directoryComponent stringByDeletingPathExtension];
			NSString *fileExtension = [path pathExtension];
			if ([directoryName isEqualToString:GREENWICH_DEFAULT_LANGUAGE] &&
				[fileExtension isEqualToString:@"strings"]) {
				
				NSString *originalPath = [resourcesPath stringByAppendingPathComponent:path];
				for (NSString *language in languages) {
					NSString *languageDirectoryName = [language stringByAppendingPathExtension:directoryExtension];
					NSString *languageDirectoryPath = [basePath stringByAppendingPathComponent:languageDirectoryName];
					NSString *languagePath = [languageDirectoryPath stringByAppendingPathComponent:fileComponent];
					NSString *translateDirectory =
						[translateBundlePath stringByAppendingPathComponent:languageDirectoryPath];
					NSString *translatePath = [translateBundlePath stringByAppendingPathComponent:languagePath];
					if (![manager fileExistsAtPath:translatePath]) {
						if ([manager createDirectoryAtPath:translateDirectory withIntermediateDirectories:YES
												attributes:nil error:error]) {
							if (![manager copyItemAtPath:originalPath toPath:translatePath error:error]) {
								translateBundle = nil;
								break;
							}
						}
						else {
							translateBundle = nil;
							break;
						}
					}
				}
			}
		}
	}
	
	return translateBundle;
}


#pragma mark -
#pragma mark strings handling
// ----------------------------------------------------------------------------------------------------
// strings handling
// ----------------------------------------------------------------------------------------------------

+ (BOOL)_mergeContentsOfStringsFile:(NSString *)mergeFromPath
			  intoStringsFileAtPath:(NSString *)mergeIntoPath
							  error:(NSError **)error {
	BOOL success = TRUE;
	FRStrings *contentsUntranslated = nil;
	FRStrings *contentsTranslated = nil;
	FRStringsFormat format = 0;
	
	if (success) {
		contentsUntranslated = [[FRStrings alloc] initWithContentsOfFile:mergeFromPath usedFormat:&format error:error];
		if (!contentsUntranslated) { success = FALSE; }
	}
	
	if (success) {
		contentsTranslated = [[FRStrings alloc] initWithContentsOfFile:mergeIntoPath usedFormat:NULL error:error];
		if (!contentsTranslated) { success = FALSE; }
	}

	if (success) {
		for (NSString *string in contentsUntranslated) {
			NSString *currentTranslation = [contentsTranslated translationForString:string];
			NSArray *currentComments = [contentsTranslated commentsForString:string];
			
			NSArray *combinedComments = [contentsUntranslated commentsForString:string];
			if (!combinedComments) { combinedComments = [NSArray array]; }
			if ([currentComments count] > [combinedComments count]) {
				NSRange range = {};
				range.location = [combinedComments count];
				range.length = [currentComments count] - [combinedComments count];
				combinedComments = [combinedComments arrayByAddingObjectsFromArray:
									[currentComments subarrayWithRange:range]];
			}
			
			if (currentTranslation) {
				[contentsUntranslated setTranslation:currentTranslation forString:string];
			}
			[contentsUntranslated setComments:combinedComments forString:string];
		}
		
		if (![contentsUntranslated writeToFile:mergeIntoPath format:format error:error]) {
			success = FALSE;
		}
	}
	
	return success;
}


#pragma mark -
#pragma mark convenience
// ----------------------------------------------------------------------------------------------------
// convenience
// ----------------------------------------------------------------------------------------------------

- (NSArray *)containedBundles {
	NSMutableArray *bundles = [[NSMutableArray alloc] init];
	[self enumerateContainedBundlesUsingBlock:^(NSBundle *bundle, BOOL *skipDescendants, BOOL *stop) {
		[bundles addObject:bundle];
	}];
	return bundles;
}

- (void)enumerateContainedBundlesUsingBlock:(void(^)(NSBundle *bundle, BOOL *skipDescendants, BOOL *stop))block {
	NSMutableArray *search = [NSMutableArray arrayWithObject:self];
		
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
		BOOL stop = FALSE;
		BOOL skipDescendants = FALSE;
		block(bundle, &skipDescendants, &stop);
		if (!skipDescendants) {
			iterate_directory([bundle privateFrameworksPath]);
			iterate_directory([bundle builtInPlugInsPath]);
		}
		[search removeObjectAtIndex:0];
		if (stop) { break; }
	}
}

@end
