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
+ (id)containerForSyncedApplicationResources:(NSURL *)resourcesURL;

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

/*!
 \brief		Check if this container is synced
 \details	This is a synced container if it was created as such. These containers
			need the extra abilities in the UI so that they can send info back and
			forth to the sync source.
 */
- (BOOL)isSynced;

@end
