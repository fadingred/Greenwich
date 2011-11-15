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

@interface FRTranslationInfo : NSObject {
	FSEventStreamRef stream;
	BOOL untranslatedKnown;
	NSUInteger untranslatedCount;
	NSString *language;
	NSString *path;
	NSString *translationPath;
	NSString *fileName;
	NSString *displayName;
	NSString *bundleName;
	NSMutableDictionary *displayInfo;
}

+ (id)infoWithLanguage:(NSString *)language path:(NSString *)path;

@property (readonly) NSString *path;

@property (readonly) NSString *fileName;
@property (readonly) NSString *displayName;
@property (readonly) NSString *bundleName;
@property (readonly) NSUInteger untranslatedCount;

@property (readonly) NSDictionary *displayInfo;

@end
