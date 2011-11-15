// 
// Copyright (c) 2011 FadingRed LLC
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

#import "FRTranslationInfo__.h"
#import "FRBundleAdditions.h"

static void filechange(ConstFSEventStreamRef, void *, size_t, void *,
					   const FSEventStreamEventFlags[], const FSEventStreamEventId[]);

@interface FRTranslationInfo (Private)
- (id)initWithLanguage:(NSString *)aLanguage path:(NSString *)path;
@end

@implementation FRTranslationInfo

+ (NSSet *)keyPathsForValuesAffectingDisplayInfo {
	return [NSSet setWithObjects:@"displayName", @"untranslatedCount", nil];
}

+ (id)infoWithLanguage:(NSString *)language path:(NSString *)path {
	return [[[self alloc] initWithLanguage:language path:path] autorelease];
}

- (id)init {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithLanguage:(NSString *)aLanguage path:(NSString *)aPath {
	if ((self = [super init])) {
		NSString *languagePath = [aPath stringByDeletingLastPathComponent];
		NSString *bundlePath = [languagePath stringByDeletingLastPathComponent];
		NSString *bundleIdentifier = [bundlePath lastPathComponent];

		// set all the properties
		path = [aPath copy];
		language = [aLanguage copy];
		fileName = [[path lastPathComponent] copy];
		displayName = [[fileName stringByDeletingPathExtension] copy];
		bundleName = [[[NSBundle bundleWithIdentifier:bundleIdentifier loaded:NULL] name] copy];
		displayInfo = [[NSMutableDictionary alloc] init];
		
		if (!bundleName) {
			NSString *directory = [aPath stringByDeletingLastPathComponent];
			while (!bundleName && ([[directory pathComponents] count] > 1)) {
				NSString *name = [directory lastPathComponent];
				if (![name isEqualToString:@"Resources"] &&
					![name isEqualToString:@"Contents"] &&
					![name isEqualToString:@"Frameworks"] &&
					![name isEqualToString:@"PlugIns"] &&
					![name isEqualToString:@"Versions"] &&
					![name isEqualToString:@"A"] &&
					![name hasSuffix:@".lproj"]) {
					bundleName = [name stringByDeletingPathExtension];
				}
				directory = [directory stringByDeletingLastPathComponent];
			}
		}
		
		if ([bundleName length]) {
			displayName = [[displayName stringByAppendingFormat:@" (%@)", bundleName] copy];
		}
		
		// setup to watch the path for changes
		CFAbsoluteTime latency = 1; // latency in seconds
		CFArrayRef pathsToWatch = (CFArrayRef)[NSArray arrayWithObject:[path stringByDeletingLastPathComponent]];
		FSEventStreamContext context = {
			.version = 0,
			.info = self,
			.retain = NULL,
			.release = NULL,
			.copyDescription = NULL,
		};
		stream = FSEventStreamCreate(NULL, filechange, &context, pathsToWatch,
									 kFSEventStreamEventIdSinceNow, latency,
									 kFSEventStreamCreateFlagNoDefer);
		FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		FSEventStreamStart(stream);
	}
	return self;
}

@synthesize path;
@synthesize fileName;
@synthesize displayName;
@synthesize bundleName;

- (void)dealloc {
	[language release];
	[path release];
	[translationPath release];
	[fileName release];
	[displayName release];
	[bundleName release];
	[displayInfo release];

	if (stream) { FSEventStreamStop(stream); }
	if (stream) { FSEventStreamInvalidate(stream); }
	if (stream) { FSEventStreamRelease(stream); }
	[super dealloc];
}

- (void)finalize {
	if (stream) { FSEventStreamStop(stream); }
	if (stream) { FSEventStreamInvalidate(stream); }
	if (stream) { FSEventStreamRelease(stream); }
	[super finalize];
}

- (NSUInteger)untranslatedCount {
	if (!untranslatedKnown) {
		untranslatedCount = 0;
		
		// calculate
		NSError *error = nil;
		BOOL hasError = FALSE;
		NSStringEncoding encoding;
		NSString *contents = [NSString stringWithContentsOfFile:self.path
												   usedEncoding:&encoding
														  error:&error];
		if (!contents) { hasError = TRUE; }
		
		if (!hasError) {
			NSArray *lines = [contents componentsSeparatedByCharactersInSet:
							  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];;
			NSString *previousLine = nil;
			for (NSString *line in lines) {
				NSArray *components = [line componentsSeparatedByString:@"\" = \""];
				if ([components count] == 2) {
					NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"\";"];
					NSString *leftSide = [[components objectAtIndex:0] stringByTrimmingCharactersInSet:trim];
					NSString *rightSide = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:trim];
					if (([leftSide isEqualToString:rightSide]) &&
						(previousLine == nil || [previousLine rangeOfString:@"=="].location == NSNotFound)) {
						untranslatedCount++;
					}
				}
				previousLine = line;
			}
		}
		
		if (hasError) {
			NSLog(@"Error getting untranslated count: %@", error);
		}
		untranslatedKnown = TRUE;
	}
	
	return untranslatedCount;
}

- (NSDictionary *)displayInfo {
	[displayInfo setObject:[NSNumber numberWithUnsignedInteger:self.untranslatedCount] forKey:@"untranslatedCount"];
	[displayInfo setObject:[self displayName] ? [self displayName] : [NSNull null] forKey:@"displayName"];
	return displayInfo;
}

- (void)updateForFileContentsChange {
	[self willChangeValueForKey:@"untranslatedCount"];
	untranslatedKnown = FALSE;
	[self didChangeValueForKey:@"untranslatedCount"];
}

@end

static void filechange(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths,
					   const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]) {
	FRTranslationInfo *info = clientCallBackInfo;
	[info updateForFileContentsChange];
	
}
