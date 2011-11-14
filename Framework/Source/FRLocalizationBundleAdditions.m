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

#import "FRLocalizationBundleAdditions.h"
#import "FRLocalizationBundleAdditions__.h"
#import "FRBundleAdditions.h"
#import "FRRuntimeAdditions.h"

@interface NSBundle (FRLocalizationBundleAdditionsPrivate)
+ (BOOL)_mergeContentsOfStringsFile:(NSString *)mergeFromPath
			  intoStringsFileAtPath:(NSString *)mergeIntoPath
							  error:(NSError **)error;
@end

// swizzling
static NSString *(*SLocalizedString)(id self, SEL _cmd, NSString *key, NSString *value, NSString *table);
static NSString *(FRLocalizedString)(id self, SEL _cmd, NSString *key, NSString *value, NSString *table);

@implementation NSBundle (FRLocalizationBundleAdditions)

+ (void)load {
	[self swizzle:@selector(localizedStringForKey:value:table:)
			 with:(IMP)FRLocalizedString store:(IMPPointer)&SLocalizedString];
}

static NSString *(FRLocalizedString)(id self, SEL _cmd, NSString *key, NSString *value, NSString *table) {
	NSBundle *bundle = self;
	NSString *bundleID = [self bundleIdentifier];
	if (bundleID) {
		NSBundle *translated = [[self class] bundleForTranslationsWithIdentifier:bundleID];
		if (translated) {
			bundle = translated;
		}
	}
	return SLocalizedString(bundle, _cmd, key, value, table);
}

+ (id)bundleForTranslationsWithIdentifier:(NSString *)identifier {
	return [self bundleForTranslationsWithIdentifier:identifier updatingStringsForLanguages:nil error:NULL];
}

+ (id)bundleForTranslationsWithIdentifier:(NSString *)identifier
			  updatingStringsForLanguages:(NSArray *)languages
									error:(NSError **)error {

	BOOL create = [languages count];
	NSFileManager *manager = [NSFileManager defaultManager];

	NSBundle *originalBundle = [self bundleWithIdentifier:identifier loaded:NULL];
	NSBundle *translateBundle = nil;
	NSString *translateBundlePath = nil;
	
	if (originalBundle) {
		NSString *appSupportPath = [[self mainBundle] applicationSupportDirectory];
		NSString *translationsPath = [appSupportPath stringByAppendingPathComponent:@"Translations"];
		translateBundlePath = [translationsPath stringByAppendingPathComponent:[originalBundle bundleIdentifier]];
		
		if (create) {
			[manager createDirectoryAtPath:translateBundlePath withIntermediateDirectories:YES
								attributes:nil error:NULL];
		}
		
		translateBundle = [NSBundle bundleWithPath:translateBundlePath];
	}

	if (translateBundle && create) {
		NSString *resourcesPath = [originalBundle resourcePath];
		NSArray *paths = [manager subpathsOfDirectoryAtPath:resourcesPath error:NULL];
		for (NSString *path in paths) {
			NSString *directoryPath = [path stringByDeletingLastPathComponent];
			NSString *directoryName = [[directoryPath lastPathComponent] stringByDeletingPathExtension];
			NSString *fileExtension = [path pathExtension];
			if ([languages containsObject:directoryName] && [fileExtension isEqualToString:@"strings"]) {
				NSString *originalPath = [resourcesPath stringByAppendingPathComponent:path];
				NSString *translatePath = [translateBundlePath stringByAppendingPathComponent:path];
				
				if ([manager fileExistsAtPath:translatePath]) {
					if (![self _mergeContentsOfStringsFile:originalPath // merge in progress translations
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
	}
	
	return translateBundle;
}

+ (BOOL)_mergeContentsOfStringsFile:(NSString *)mergeFromPath
			  intoStringsFileAtPath:(NSString *)mergeIntoPath
							  error:(NSError **)error {
	BOOL success = TRUE;
	NSString *contentsUntranslated = nil;
	NSString *contentsTranslated = nil;
	
	if (success) {
		contentsUntranslated = [NSString stringWithContentsOfFile:mergeFromPath
													 usedEncoding:&(NSStringEncoding){ 0 } error:error];
		if (!contentsUntranslated) { success = FALSE; }
	}
	
	if (success) {
		contentsTranslated = [NSString stringWithContentsOfFile:mergeIntoPath usedEncoding:&(NSStringEncoding){ 0 } error:error];
		if (!contentsTranslated) { success = FALSE; }
	}

	if (success) {
		NSMutableString *result = [NSMutableString string];
		
		NSArray *untranslatedLines = [contentsUntranslated componentsSeparatedByCharactersInSet:
									  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];

		NSArray *translatedLines = [contentsTranslated componentsSeparatedByCharactersInSet:
									[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
		
		NSMutableDictionary *translatedKeys = [NSMutableDictionary dictionary];
		NSMutableArray *previousComments = [NSMutableArray array];
		static NSString * const kCommentsKey = @"comments";
		static NSString * const kValueKey = @"value";
		for (NSString *line in translatedLines) {
			NSArray *components = [line componentsSeparatedByString:@"\" = \""];
			if ([components count] == 2) {
				NSString *leftSide = [NSString stringWithFormat:@"%@\"", [components objectAtIndex:0]];
				NSString *rightSide = [NSString stringWithFormat:@"\"%@", [components objectAtIndex:1]];
				NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
									  previousComments, kCommentsKey,
									  rightSide, kValueKey, nil];
				[translatedKeys setObject:info forKey:leftSide];
				previousComments = [NSMutableArray array];
			}
			else if ([line hasPrefix:@"/*"] && [line hasSuffix:@"*/"]) {
				[previousComments addObject:line];
			}
			else { previousComments = [NSMutableArray array]; }
		}
		
		NSUInteger commentCount = 0;
		for (NSString *line in untranslatedLines) {
			NSString *editedLine = nil;
			NSArray *components = [line componentsSeparatedByString:@"\" = \""];
			if ([components count] == 2) {
				NSString *leftSide = [NSString stringWithFormat:@"%@\"", [components objectAtIndex:0]];
				NSString *rightSide = [NSString stringWithFormat:@"\"%@", [components objectAtIndex:1]];
				NSString *newRightSide = rightSide;
				if ([translatedKeys valueForKey:leftSide]) {
					NSDictionary *info = [translatedKeys valueForKey:leftSide];
					NSArray *comments = [info objectForKey:kCommentsKey];
					for (NSUInteger idx = commentCount; idx < [comments count]; idx++) {
						[result appendFormat:@"%@\n", [comments objectAtIndex:idx]];
					}
					newRightSide = [info objectForKey:kValueKey];
				}
				editedLine = [NSString stringWithFormat:@"%@ = %@", leftSide, newRightSide];
				commentCount = 0;
			}
			else {
				if ([line hasPrefix:@"/*"] && [line hasSuffix:@"*/"]) { commentCount++; }
				else { commentCount = 0; }
				editedLine = line;
			}
			[result appendFormat:@"%@\n", editedLine];
		}
		
		if (![result writeToFile:mergeIntoPath atomically:YES encoding:NSUTF16StringEncoding error:error]) {
			success = FALSE;
		}
	}
	
	return success;
}

@end
