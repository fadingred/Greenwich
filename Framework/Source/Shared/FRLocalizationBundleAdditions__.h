// 
// Copyright (c) 2013 FadingRed LLC
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

@interface NSBundle (FRLocalizationBundleAdditionsInternal)

/*!
 \brief		Get the bundle contining user translations
 \details	This will create and merge strings files for the given langauges. It will create the bundle
			if any launage is specified, but will not create it if no languages are given. Error will be
			set when this method returns nil and a real error occurred (not just that the bundle was not
			created).
 */
- (id)bundleUsingContentsForTranslationsWithIdentifier:(NSString *)bundleIdentifier
						   updatingStringsForLanguages:(NSArray *)languages
												 error:(NSError **)error;

/*!
 \brief		Get all sub-bundles of a bundle
 \details	Search for all sub bundles of a given bundle. Will return an array containing anything that
			appears to be a bundle because it has defined a bundle identifier in the proper place.
 */
- (NSArray *)containedBundles;

/*!
 \brief		Enumerate all sub-bundles of a bundle
 \details	Search for all sub bundles of a given bundle. Will call block for anything that
			appears to be a bundle because it has defined a bundle identifier in the proper place.
 */
- (void)enumerateContainedBundlesUsingBlock:(void(^)(NSBundle *bundle, BOOL *skipDescendants, BOOL *stop))block;

@end
