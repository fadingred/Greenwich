//
//  FRTranslator.m
//  Greenwich Translator
//
//  Created by Whitney Young on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "FRTranslator.h"
#import "FRLocalizationWindowController.h"
#import "FRTranslationContainer__.h"

static NSString * const kUbiquityIdentifier = @"5AD9N78AKC.com.fadingred.greenwich.translations";
static NSString * const kLastUsedKey = @"FRLastUsed";
static NSString * const kApplicationNameKey = @"FRApplicationName";

@interface FRTranslator ()
- (void)queryDidUpdate:(NSNotification *)notification;
- (void)queryDidFinishGathering:(NSNotification *)notification;
@end

@implementation FRTranslator

+ (FRLocalizationWindowController *)sharedLocalizationWindowController {
	static FRLocalizationWindowController *controller = nil;
	if (!controller) {
		controller = [[FRLocalizationWindowController alloc] init];
	}
	return controller;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSURL *ubiquity = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:kUbiquityIdentifier];
	NSURL *usage = [ubiquity URLByAppendingPathComponent:@"usage.plist"];
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSDate date], kLastUsedKey, nil];
	[info writeToURL:usage atomically:YES];
	
	[[[self class] sharedLocalizationWindowController] showWindow:nil];
	
	static NSMetadataQuery *query = nil;
	if (!query) {
		query = [[NSMetadataQuery alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidUpdate:)
													 name:NSMetadataQueryDidUpdateNotification
												   object:query];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryDidFinishGathering:)
													 name:NSMetadataQueryDidFinishGatheringNotification
												   object:query];

		[query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope]];
		[query setPredicate:[NSPredicate predicateWithFormat:@"%K == 'GreenwichInfo.plist'", NSMetadataItemFSNameKey]];
		[query startQuery];
	}
}

- (void)processUpdates:(NSMetadataQuery *)query {
	[query disableUpdates];
	
	for (NSUInteger i = 0; i < [query resultCount]; i++) {
		NSMetadataItem *theResult = [query resultAtIndex:i];
		NSString *path = [theResult valueForAttribute:(NSString *)kMDItemPath];
		NSURL *appInfoURL = [NSURL fileURLWithPath:path];
		NSURL *appURL = [appInfoURL URLByDeletingLastPathComponent];
		NSDictionary *appInfo = [NSDictionary dictionaryWithContentsOfURL:appInfoURL];
		if (appInfo) {
			FRTranslationContainer *container = [FRTranslationContainer containerForCloudSyncedResources:appURL];
			container.name = [appInfo objectForKey:kApplicationNameKey];
			[[[self class] sharedLocalizationWindowController] addContainer:container];
		}
	}
	
	[query enableUpdates];
}

- (void)queryDidUpdate:(NSNotification *)notification {
	[self processUpdates:[notification object]];
}

- (void)queryDidFinishGathering:(NSNotification *)notification {
	[self processUpdates:[notification object]];
}

@end
