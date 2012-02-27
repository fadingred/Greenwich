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

#import "FRTranslationContainer__.h"
#import "FRTranslationInfo__.h"

#import "FRBundleAdditions.h"
#import "FRLocalizationBundleAdditions.h"
#import "FRLocalizationBundleAdditions__.h"

static NSString * const FRLocalizationIgnoreBundlesKey = @"FRLocalizationIgnoreBundles";

@implementation FRTranslationContainer

@synthesize name;

+ (void)initialize {
	if (self == [FRTranslationContainer class]) {
		NSArray *ignoreBundles = [NSArray arrayWithObjects:@"Sparkle", nil];
		[[NSUserDefaults standardUserDefaults] registerDefaults:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  ignoreBundles, FRLocalizationIgnoreBundlesKey, nil]];
	}
}

+ (id)containerForApplicationBundle:(NSBundle *)bundle {
	FRTranslationContainer *continer = [[self alloc] init];
	continer->applicationBundle = bundle;
	return continer;
}

+ (id)containerForSyncedApplicationResources:(NSURL *)aURL {
	FRTranslationContainer *continer = [[self alloc] init];
	continer->resourcesURL = aURL;
	return continer;
}

- (NSArray *)translateBundlesForLanguage:(NSString *)language {
	NSArray *languages = [NSArray arrayWithObjects:language, nil];
	if (applicationBundle) {
		NSMutableArray *result = [NSMutableArray array];
		NSSet *ignoreBundles = [NSSet setWithArray:
								[[NSUserDefaults standardUserDefaults] objectForKey:FRLocalizationIgnoreBundlesKey]];
		[applicationBundle enumerateContainedBundlesUsingBlock:^(NSBundle *bundle, BOOL *skipDescendants, BOOL *stop) {
			if ([ignoreBundles containsObject:[bundle name]]) {
				*skipDescendants = TRUE;
			}
			else {
				NSBundle *translateBundle =
					[bundle bundleUsingContentsForTranslationsWithIdentifier:[bundle bundleIdentifier]
												 updatingStringsForLanguages:languages error:NULL];
				if (translateBundle) {
					[result addObject:translateBundle];
				}
			}
		}];
		return result;
	}
	else if (resourcesURL) {
		NSMutableArray *result = [NSMutableArray array];
		NSFileManager *manager = [NSFileManager defaultManager];
		for (NSString *fileName in [manager contentsOfDirectoryAtPath:[resourcesURL path] error:NULL]) {
			if ([fileName isEqualToString:@"Greenwich.details"]) { continue; }
			NSBundle *bundle = [NSBundle bundleWithURL:[resourcesURL URLByAppendingPathComponent:fileName]];
			NSBundle *translateBundle =
				[bundle bundleUsingContentsForTranslationsWithIdentifier:[[bundle bundlePath] lastPathComponent]
											 updatingStringsForLanguages:languages error:NULL];

			if (translateBundle) {
				[result addObject:translateBundle];
			}
		}
		return result;
	}
	else { return nil; }
}

- (NSArray *)launagues {
	NSMutableSet *languages = [NSMutableSet set];
	if (applicationBundle) {
		NSArray *lprojPaths = [applicationBundle pathsForResourcesOfType:@"lproj" inDirectory:nil];
		for (NSString *path in lprojPaths) {
			NSString *language = [[path lastPathComponent] stringByDeletingPathExtension];
			if (![language isEqualToString:GREENWICH_DEFAULT_LANGUAGE]) {
				[languages addObject:language];
			}
		}
	}
	else if (resourcesURL) {
		NSFileManager *manager = [NSFileManager defaultManager];
		for (NSURL *url in [manager enumeratorAtPath:[resourcesURL path]]) {
			NSString *baseName = [url lastPathComponent];
			if ([baseName hasSuffix:@".lproj"]) {
				[languages addObject:[baseName stringByDeletingPathExtension]];

			}
		}
	}
	return [languages allObjects];
}

- (NSArray *)infoItemsForLanguage:(NSString *)language error:(NSError **)error {
	error = error ? error : &(NSError *){ nil };
	
	NSArray *translateBundles = [self translateBundlesForLanguage:language];
	NSMutableArray *content = [NSMutableArray array];
	BOOL success = TRUE;
	
	for (NSBundle *bundle in translateBundles) {
		NSArray *paths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:[bundle bundlePath] error:error];
		if (paths) {
			for (NSString *path in paths) {
				NSString *directoryPath = [path stringByDeletingLastPathComponent];
				NSString *directoryName = [[directoryPath lastPathComponent] stringByDeletingPathExtension];
				NSString *fileExtension = [path pathExtension];
				if ([directoryName isEqualToString:language] && [fileExtension isEqualToString:@"strings"]) {
					NSString *infoPath = [[bundle bundlePath] stringByAppendingPathComponent:path];
					FRTranslationInfo *info = [FRTranslationInfo infoWithLanguage:language path:infoPath];
					[content addObject:info];
				}
			}
		}
		else { success = FALSE; break; }
	}
	
	return success ? content : nil;
}

- (BOOL)isSynced {
	return (resourcesURL != nil);
}

@end
