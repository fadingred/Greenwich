//
//  FRTranslationContainer.m
//  Greenwich
//
//  Created by Whitney Young on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "FRTranslationContainer__.h"
#import "FRTranslationInfo__.h"

#import "FRLocalizationBundleAdditions.h"
#import "FRLocalizationBundleAdditions__.h"

@implementation NSBundle (FRTranslationContainerAdditions)

- (NSArray *)localizableBundles {
	NSMutableArray *bundles = [[NSMutableArray alloc] init];
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

	return bundles;
}

- (NSArray *)translateBundlesForLanguage:(NSString *)language {
	NSArray *languages = [NSArray arrayWithObjects:language, nil];
	NSMutableArray *translatedBundles = [NSMutableArray array];
	
	for (NSBundle *bundle in [self localizableBundles]) {
		NSBundle *translatedBundle = [NSBundle bundleForTranslationsWithIdentifier:[bundle bundleIdentifier]
													   updatingStringsForLanguages:languages error:NULL];
		if (translatedBundle) {
			[translatedBundles addObject:translatedBundle];
		}
	}
	
	return translatedBundles;
}


@end

@implementation FRTranslationContainer

@synthesize name;

+ (id)containerForApplicationBundle:(NSBundle *)bundle {
	FRTranslationContainer *continer = [[self alloc] init];
	continer->applicationBundle = bundle;
	return continer;
}

+ (id)containerForCloudSyncedResources:(NSURL *)aURL {
	FRTranslationContainer *continer = [[self alloc] init];
	continer->resourcesURL = aURL;
	return continer;
}

- (NSArray *)translateBundlesForLanguage:(NSString *)language {
	if (applicationBundle) {
		return [applicationBundle translateBundlesForLanguage:language];
	}
	else if (resourcesURL) {
		NSMutableArray *result = [NSMutableArray array];
		NSFileManager *manager = [NSFileManager defaultManager];
		for (NSString *fileName in [manager contentsOfDirectoryAtPath:[resourcesURL path] error:NULL]) {
			if (![fileName isEqualToString:@"GreenwichInfo.plist"]) {
				NSBundle *bundle = [NSBundle bundleWithURL:[resourcesURL URLByAppendingPathComponent:fileName]];
				if (bundle) {
					[result addObject:bundle];
				}
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
					if (![[info bundleName] isEqualToString:@"Sparkle"]) {
						[content addObject:info];
					}
				}
			}
		}
		else { success = FALSE; break; }
	}
	
	return success ? content : nil;
}

@end
