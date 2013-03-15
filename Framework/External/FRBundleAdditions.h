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

@interface NSBundle (FRBundleAdditions)

/*!
 \brief			Find a bundle by identifier
 \details		This will find a bundle for the given identifier. It is similar to
				NSBundle::bundleWithIdentifier, but doesn't just look at loaded
				bundles. It will also look for bundles embeded in the main application
				bundle and recursively searching for bundles. The results are cached
				after the first invocation to keep the method efficient. With iOS this
				can be used by frameworks and bundles to find resources they use (since
				loadable frameworks and bundles aren't allowed on iOS).
 */
+ (id)bundleWithIdentifier:(NSString *)identifier loaded:(BOOL *)isLoaded;

/*!
 \brief		Bundle name
 \details	Trys to look up bundle name first by
			CFBundleDisplayName, then by CFBundleName,
			and then by CFBundleExecutable.
 */
- (NSString *)name;

/*!
 \brief		Bundle version
 \details	Trys to look up bundle version by
			CFBundleVersion.
 */
- (NSString *)version;

/*!
 \brief		The application suport directory for the bunlde
 \details	Gets the application support directory for this bundle
			by searching for the correct directory, then appending
			the name of the bundle. Will not create the directory.
 */
- (NSString *)applicationSupportDirectory;

/*!
 \brief		Alternative private frameworks path	
 \details	Frameworks may store sub-frameworks at a different location from what the standard private
			frameworks path returns. It could be stored alongside the executable in the version
			directory. This is where Xcode places it during the copy frameworks build phase. Returns nil
			if there is no alternative path for this type of bundle.
 */
- (NSString *)alternativePrivateFrameworksPath;

/*!
 \brief		Builtin bundles path
 \details	Contains bundles for resources. Mostly used on iOS.
 */
- (NSString *)builtInBundlesPath;

@end
