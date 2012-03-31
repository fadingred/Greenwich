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

#import <objc/runtime.h>

#import "FRLocalizationManager.h"
#import "FRNetworkServer__.h"
#import "FRBundleAdditions.h"
#import "FRMessages.h"
#import "FRLocalizationBundleAdditions__.h"

static NSString * const kAuthorizedDevicesKey = @"FRTranslatorAuthorizedDevices";
static const char kConfirmationKey;
static const char kCancelationKey;
static const char kAuthorizedKey;

@interface FRLocalizationManager () <FRNetworkServerDelegate>
- (NSDictionary *)localizationResourcesMessage;
- (void)extractUpdatedStringsFromResourcesMessage:(NSDictionary *)message;
@end

@interface FRConnection (FRAuthorizationAdditions)
@property (nonatomic, assign, getter=isAuthorized) BOOL authorized;
@end

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

- (id)init {
	if ((self = [super init])) {
		server = [[FRNetworkServer alloc] init];
		server.delegate = self;
	}
	return self;
}

- (void)networkServer:(FRNetworkServer *)server
	  receivedMessage:(NSDictionary *)message
	   fromConnection:(FRConnection *)connection {
	
	BOOL isAuthorized = [connection isAuthorized];
	if (isAuthorized) {
		if ([message objectForKey:FRLocalizationChangesMessage.messageID]) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[self extractUpdatedStringsFromResourcesMessage:message];
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString *title = FRLocalizedString(@"New Localizations", nil);
					NSString *details =
						FRLocalizedString(@"You have added new localizations to the application. To see these "
										  @"localization, you will need to terminate the application and then start it "
										  @"again.", nil);
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:details delegate:self
														  cancelButtonTitle:FRLocalizedString(@"Cancel", nil)
														  otherButtonTitles:FRLocalizedString(@"Terminate", nil), nil];
					void (^complete)(void) = ^{
						UIApplication *application = [UIApplication sharedApplication];
						id <UIApplicationDelegate> delegate = [application delegate];
						if ([delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
							[delegate applicationWillTerminate:application];
						}
						exit(0);
					};
					objc_setAssociatedObject(alert, &kConfirmationKey, complete, OBJC_ASSOCIATION_COPY_NONATOMIC);
					
					[alert show];
				});
			});
		}
	}
	else if ([message objectForKey:FRAuthenticationMessage.messageID]) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSArray *authorizedDevices = [userDefaults objectForKey:kAuthorizedDevicesKey];
		NSString *deviceIdentifier = [message objectForKey:FRAuthenticationMessage.keys.deviceIdentifier];
		
		void (^performActionsForValidAuthentication)(void) = ^{
			// on initial authorization, send all strings to the client
			[connection setAuthorized:YES];
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSDictionary *response = [self localizationResourcesMessage];
				dispatch_async(dispatch_get_main_queue(), ^{
					[connection sendMessage:response];
				});
			});
		};
		
		if ([authorizedDevices containsObject:deviceIdentifier]) {
			performActionsForValidAuthentication();
		}
		else {
			NSString *deviceName = [message objectForKey:FRAuthenticationMessage.keys.deviceName];
			NSString *title = FRLocalizedString(@"Localization Setup", nil);
			NSString *details = 
				[NSString stringWithFormat:
				 FRLocalizedString(@"The computer \"%@\" would like to communicate with your device allowing you "
								   @"to localize this application.", nil), deviceName];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:details delegate:self
												  cancelButtonTitle:FRLocalizedString(@"Cancel", nil)
												  otherButtonTitles:FRLocalizedString(@"Authorize", nil), nil];
			
			void (^authorize)(void) = ^{
				NSMutableArray *updatedDevices = [NSMutableArray arrayWithArray:authorizedDevices];
				[updatedDevices addObject:deviceIdentifier];
				[userDefaults setObject:updatedDevices forKey:kAuthorizedDevicesKey];
				[userDefaults synchronize];
				performActionsForValidAuthentication();
			};
			void (^cancel)(void) = ^{ [connection close]; };

			objc_setAssociatedObject(alert, &kConfirmationKey, authorize, OBJC_ASSOCIATION_COPY_NONATOMIC);
			objc_setAssociatedObject(alert, &kCancelationKey, cancel, OBJC_ASSOCIATION_COPY_NONATOMIC);
			
			[alert show];
		}
	}
	else {
		// cose connection on invalid, unauthorized messages
		[connection close];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	void (^block)(void) = nil;
	if (buttonIndex == [alertView cancelButtonIndex]) {
		block = objc_getAssociatedObject(alertView, &kCancelationKey);
	} else {
		block = objc_getAssociatedObject(alertView, &kConfirmationKey);
	}
	if (block) { block(); }
}

- (NSDictionary *)localizationResourcesMessage {
	NSMutableArray *languages = [NSMutableArray array];
	NSArray *lprojPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"lproj" inDirectory:nil];
	for (NSString *path in lprojPaths) {
		[languages addObject:
		 [[path lastPathComponent] stringByDeletingPathExtension]];
	}
	
	NSMutableArray *resources = [NSMutableArray array];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	// TODO: could ignore certain contained bundles here by enumerating contained bundles and skipping
	// the bundle and descendants if the bundle name is in FRLocalizationIgnoreBundlesKey
	NSArray *containedBundles = [[NSBundle mainBundle] containedBundles];
	NSMutableSet *containedBundlePaths = [NSMutableSet set];
	for (NSBundle *bundle in containedBundles) {
		[containedBundlePaths addObject:[bundle bundlePath]];
	}
	for (NSBundle *bundle in containedBundles) {
		NSString *bundleIdentifier = [bundle bundleIdentifier];
		NSString *bundlePath = [[bundle resourceURL] path];
		// using an enumerator because subpathsOfDirectoryAtPath doesn't traverse the path
		// if it's a symbolic link (even though it's documented to traverse it)
		NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:bundlePath];
		for (NSString *path in enumerator) {
			if ([containedBundlePaths containsObject:
				 [bundlePath stringByAppendingPathComponent:path]]) { [enumerator skipDescendants]; continue; }
			
			NSString *directoryPath = [path stringByDeletingLastPathComponent];
			NSString *directoryName = [[directoryPath lastPathComponent] stringByDeletingPathExtension];
			NSString *fileExtension = [path pathExtension];
			if ([languages containsObject:directoryName] && [fileExtension isEqualToString:@"strings"]) {
				NSString *name = [[path lastPathComponent] stringByDeletingPathExtension];
				NSString *filePath = [bundlePath stringByAppendingPathComponent:path];
				NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:NULL];
				[resources addObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:
				  bundleIdentifier, FRLocalizationResourcesMessage.keys.resource.bundleIdentifier,
				  directoryName, FRLocalizationResourcesMessage.keys.resource.language,
				  name, FRLocalizationResourcesMessage.keys.resource.name,
				  data, FRLocalizationResourcesMessage.keys.resource.data, nil]];
				
			}
		}
	}

	return [NSDictionary dictionaryWithObjectsAndKeys:
			FRLocalizationResourcesMessage.messageID, FRLocalizationResourcesMessage.messageID,
			resources, FRLocalizationResourcesMessage.keys.resources, 
			[[NSBundle mainBundle] name], FRLocalizationResourcesMessage.keys.applicationName,
			[[NSBundle mainBundle] bundleIdentifier], FRLocalizationResourcesMessage.keys.applicationIdentifier, nil];
}

- (void)extractUpdatedStringsFromResourcesMessage:(NSDictionary *)message {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *applicationSupport = [[NSBundle mainBundle] applicationSupportDirectory];
	NSString *translationsDirectory = [applicationSupport stringByAppendingPathComponent:@"Translations"];
	
	for (NSDictionary *resource in [message objectForKey:FRLocalizationChangesMessage.keys.resources]) {
		NSString *bundleID = [resource objectForKey:FRLocalizationChangesMessage.keys.resource.bundleIdentifier];
		NSString *language = [resource objectForKey:FRLocalizationChangesMessage.keys.resource.language];
		NSString *name = [resource objectForKey:FRLocalizationChangesMessage.keys.resource.name];
		NSData *data = [resource objectForKey:FRLocalizationChangesMessage.keys.resource.data];
		
		NSString *bundleDirectory = [translationsDirectory stringByAppendingPathComponent:bundleID];
		NSString *lprojName = [NSString stringWithFormat:@"%@.lproj", language];
		NSString *lprojDirectory = [bundleDirectory stringByAppendingPathComponent:lprojName];
		NSString *stringsName = [NSString stringWithFormat:@"%@.strings", name];
		NSString *stringsPath = [lprojDirectory stringByAppendingPathComponent:stringsName];
		
		[manager createDirectoryAtPath:lprojDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
		[data writeToFile:stringsPath options:0 error:NULL];
	}
}

@end

@implementation FRConnection (FRAuthorizationAdditions)
- (BOOL)isAuthorized { return [objc_getAssociatedObject(self, &kAuthorizedKey) boolValue]; }
- (void)setAuthorized:(BOOL)flag {
	objc_setAssociatedObject(self, &kAuthorizedKey, [NSNumber numberWithBool:flag], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
