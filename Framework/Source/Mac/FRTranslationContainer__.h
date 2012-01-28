//
//  FRTranslationContainer.h
//  Greenwich
//
//  Created by Whitney Young on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

@interface FRTranslationContainer : NSObject {
@private;
	NSBundle *applicationBundle;
	NSURL *resourcesURL;
}

/*!
 \brief		Create a container for an application
 \details	The container will determine localizable resources
			by scanning the application bundle.
 */
+ (id)containerForApplicationBundle:(NSBundle *)bundle;

/*!
 \brief		Create a container for an application
 \details	The container will determine localizable resources
			by scanning the contents of the directory at the
			given URL.
 */
+ (id)containerForCloudSyncedResources:(NSURL *)resourcesURL;

/*!
 \brief		The container name
 \details	Get or set the container name
 */
@property (retain) NSString *name;

/*!
 \brief		Accesses the languages
 \details	This will look up languages for the container.
			It could be very slow.
 */
- (NSArray *)launagues;

/*!
 \brief		Accesses the languages
 \details	This will look up or create translation info objects for the given
			language in this container.
			It could be very slow.
 */
- (NSArray *)infoItemsForLanguage:(NSString *)language error:(NSError **)error;

@end
