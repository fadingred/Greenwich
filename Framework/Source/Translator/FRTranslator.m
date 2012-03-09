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

#import "FRTranslator.h"
#import "FRNetworkClient.h"
#import "FRBundleAdditions.h"
#import "FRMessages.h"
#import "FRLocalizationWindowController.h"
#import "FRTranslationContainer__.h"
#import "FRTranslationInfo__.h"

static NSString * const kApplicationNameKey = @"FRApplicationName";

@interface FRTranslator () <FRNetworkClientDelegate>
- (void)extractStringsFromResourcesMessage:(NSDictionary *)message;
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

- (id)init {
	if ((self = [super init])) {
		knownContainers = [[NSMutableSet alloc] init];
		client = [[FRNetworkClient alloc] init];
		client.delegate = self;
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
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

		NSURL *appSupport = [NSURL fileURLWithPath:[[NSBundle mainBundle] applicationSupportDirectory]];
		[query setSearchScopes:[NSArray arrayWithObjects:appSupport, nil]];
		[query setPredicate:[NSPredicate predicateWithFormat:@"%K == 'Greenwich.details'", kMDItemFSName]];
		[query startQuery];
	}
}


#pragma mark -
#pragma mark medata query support
// ----------------------------------------------------------------------------------------------------
// medata query support
// ----------------------------------------------------------------------------------------------------

- (void)processUpdates:(NSMetadataQuery *)query {
	[query disableUpdates];
	
	FRLocalizationWindowController *windowController = [[self class] sharedLocalizationWindowController];
	
	for (NSUInteger i = 0; i < [query resultCount]; i++) {
		NSMetadataItem *theResult = [query resultAtIndex:i];
		NSString *path = [theResult valueForAttribute:(NSString *)kMDItemPath];
		if (![knownContainers containsObject:path]) {
			NSURL *appInfoURL = [NSURL fileURLWithPath:path];
			NSURL *appURL = [appInfoURL URLByDeletingLastPathComponent];
			NSDictionary *appInfo = [NSDictionary dictionaryWithContentsOfURL:appInfoURL];
			if (appInfo) {
				FRTranslationContainer *container =
					[FRTranslationContainer containerForSyncedApplicationResources:appURL];
				container.name = [appInfo objectForKey:kApplicationNameKey];
				[windowController addContainer:container];
			}
			[knownContainers addObject:path];
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


#pragma mark -
#pragma mark actions
// ----------------------------------------------------------------------------------------------------
// actions
// ----------------------------------------------------------------------------------------------------

- (void)sendStringsFilesToDevice:(NSArray *)objects {
	// TODO: should show an alert if we can't send to the device
	
	FRConnection *connection = [client activeConnection];
	NSMutableArray *resources = [NSMutableArray array];

	for (FRTranslationInfo *info in objects) {
		NSString *bundleIdentifier = [info bundleIdentifier];
		NSString *name = [[info fileName] stringByDeletingPathExtension];
		NSString *language = [info language];
		NSString *filePath = [info path];
		NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:NULL];
		[resources addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  bundleIdentifier, FRLocalizationChangesMessage.keys.resource.bundleIdentifier,
		  language, FRLocalizationChangesMessage.keys.resource.language,
		  name, FRLocalizationChangesMessage.keys.resource.name,
		  data, FRLocalizationChangesMessage.keys.resource.data, nil]];
	}
	
	[connection sendMessage:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  FRLocalizationChangesMessage.messageID, FRLocalizationChangesMessage.messageID,
	  resources, FRLocalizationChangesMessage.keys.resources, nil]];
}


#pragma mark -
#pragma mark network connections
// ----------------------------------------------------------------------------------------------------
// network connections
// ----------------------------------------------------------------------------------------------------

- (void)networkClient:(FRNetworkClient *)client
	  receivedMessage:(NSDictionary *)message
	   fromConnection:(FRConnection *)connection {
	
	if ([message objectForKey:FRLocalizationResourcesMessage.messageID]) {
		[self extractStringsFromResourcesMessage:message];
	}
}

- (void)extractStringsFromResourcesMessage:(NSDictionary *)message {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *applicationSupport = [[NSBundle mainBundle] applicationSupportDirectory];
	NSString *translationsDirectory = [applicationSupport stringByAppendingPathComponent:@"Applications"];
	
	NSString *applicationName = [message objectForKey:FRLocalizationResourcesMessage.keys.applicationName];
	NSString *applicationIdentifier = [message objectForKey:FRLocalizationResourcesMessage.keys.applicationIdentifier];
	NSString *applicationStorage = [translationsDirectory stringByAppendingPathComponent:applicationIdentifier];
	
	// clear old data
	[manager removeItemAtPath:applicationStorage error:NULL];
	
	for (NSDictionary *resource in [message objectForKey:FRLocalizationResourcesMessage.keys.resources]) {
		NSString *bundleID = [resource objectForKey:FRLocalizationResourcesMessage.keys.resource.bundleIdentifier];
		NSString *language = [resource objectForKey:FRLocalizationResourcesMessage.keys.resource.language];
		NSString *name = [resource objectForKey:FRLocalizationResourcesMessage.keys.resource.name];
		NSData *data = [resource objectForKey:FRLocalizationResourcesMessage.keys.resource.data];
		
		NSString *bundleDirectory = [applicationStorage stringByAppendingPathComponent:bundleID];
		NSString *lprojName = [NSString stringWithFormat:@"%@.lproj", language];
		NSString *lprojDirectory = [bundleDirectory stringByAppendingPathComponent:lprojName];
		NSString *stringsName = [NSString stringWithFormat:@"%@.strings", name];
		NSString *stringsPath = [lprojDirectory stringByAppendingPathComponent:stringsName];
		
		[manager createDirectoryAtPath:lprojDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
		[data writeToFile:stringsPath options:0 error:NULL];
	}
	
	// write out the name and info to the Greenwich.details file
	NSString *detailsPath = [applicationStorage stringByAppendingPathComponent:@"Greenwich.details"];
	NSDictionary *details = [NSDictionary dictionaryWithObjectsAndKeys:applicationName, kApplicationNameKey, nil];
	[details writeToFile:detailsPath atomically:YES];
}

@end
