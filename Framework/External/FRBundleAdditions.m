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

#ifndef REDLINKED_BUNDLE_ADDITIONS

#import "FRBundleAdditions.h"

@implementation NSBundle (FRBundleAdditions)

+ (id)bundleWithIdentifier:(NSString *)identifier loaded:(BOOL *)isLoaded {
	static NSMutableDictionary *cache = nil;
	if (cache == nil) { @synchronized(self) { if (cache == nil) {
		cache = [[NSMutableDictionary alloc] init];
		NSMutableArray *search = [NSMutableArray arrayWithObject:[NSBundle mainBundle]];

		void (^iterate_directory)(NSString *) = ^(NSString *directory) {
			NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
			for (NSString *path in contents) {
				NSBundle *bundle = [NSBundle bundleWithPath:[directory stringByAppendingPathComponent:path]];
				if (bundle) {
					[search addObject:bundle];
				}
			}
		};

		while ([search count]) {
			NSBundle *bundle = [search objectAtIndex:0];
			iterate_directory([bundle privateFrameworksPath]);
			iterate_directory([bundle builtInPlugInsPath]);
			
			NSString *bundleID = [bundle objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
			if (bundleID) {
				[cache setObject:bundle forKey:bundleID];
			}

			[search removeObjectAtIndex:0];
		}
	}}}
	
	id bundle = nil;
	if (!bundle) { // look at loaded bundles
		bundle = [NSBundle bundleWithIdentifier:identifier];
		if (bundle && isLoaded) { *isLoaded = TRUE; }
	}
	if (!bundle) { // look at unloaded bundles
		bundle = [cache objectForKey:identifier];
		if (bundle && isLoaded) { *isLoaded = FALSE; }
	}
	return bundle;
}

- (NSString *)name {
	NSString *name = [self objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (!name) { name = [self objectForInfoDictionaryKey:@"CFBundleName"]; }
	if (!name) { name = [self objectForInfoDictionaryKey:@"CFBundleExecutable"]; }
	return name;
}

- (NSString *)version {
	return [self objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)applicationSupportDirectory {
	NSArray *search = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	return [search count] ? [[search objectAtIndex:0] stringByAppendingPathComponent:[self name]] : nil;
}

@end

#endif
