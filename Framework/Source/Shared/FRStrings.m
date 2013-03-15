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

#import "FRStrings.h"

static NSString * const kCommentsKey = @"comments";
static NSString * const kTranslationKey = @"translation";

@interface FRStrings ()
- (void)setupWithPropertyList:(NSDictionary *)plist;
- (void)setupWithQuotedString:(NSString *)string;
@end

@implementation FRStrings

- (id)init {
	if ((self = [super init])) {
		strings = [[NSMutableDictionary alloc] init];
		order = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path usedFormat:(FRStringsFormat *)outFormat error:(NSError **)error {
	NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
	return data ? [self initWithData:data usedFormat:outFormat error:error] : nil;
}

- (id)initWithData:(NSData *)data usedFormat:(FRStringsFormat *)outFormat error:(NSError **)error {
	FRStringsFormat format = 0;
	BOOL created = FALSE;
	
	if ((self = [self init])) {
		if (!created) {
			NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable
																			 format:&format error:error];
			if (plist && format != NSPropertyListOpenStepFormat) {
				[self setupWithPropertyList:plist];
				format = FRStringsFormatPropertyList;
				created = TRUE;
			}
		}
		
		if (!created) {
			NSString *string = [[NSString alloc] initWithBytes:[data bytes]
														length:[data length]
													  encoding:NSUTF8StringEncoding];
			if (string == nil) {
				string = [[NSString alloc] initWithBytes:[data bytes]
												  length:[data length]
												encoding:NSUTF16StringEncoding];
			}
			if (string) {
				[self setupWithQuotedString:string];
				format = FRStringsFormatQuoted;
				created = TRUE;
			}
		}

	}
	
	if (outFormat) { *outFormat = format; }
	
	return created ? self : nil;
}

- (id)initWithString:(NSString *)string usedFormat:(FRStringsFormat *)outFormat error:(NSError **)error {
	FRStringsFormat format = 0;
	BOOL created = FALSE;
	
	if ((self = [self init])) {
		if (!created) {
			NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable
																			 format:&format error:error];
			if (plist && format != NSPropertyListOpenStepFormat) {
				[self setupWithPropertyList:plist];
				format = FRStringsFormatPropertyList;
				created = TRUE;
			}
		}
		
		if (!created) {
			if (string) {
				[self setupWithQuotedString:string];
				format = FRStringsFormatQuoted;
				created = TRUE;
			}
		}
		
	}
	
	if (outFormat) { *outFormat = format; }
	
	return created ? self : nil;
}

- (void)setupWithPropertyList:(NSDictionary *)plist {
	for (NSString *string in plist) {
		NSString *translation = [plist objectForKey:string];
		NSMutableDictionary *object = [NSMutableDictionary dictionary];
		if (translation) { [object setObject:translation forKey:kTranslationKey]; }
		[strings setObject:object forKey:string];
		[order addObject:string];
	}
}

- (void)setupWithQuotedString:(NSString *)quotedString {
	NSCharacterSet *breaksCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
	NSArray *lines = [quotedString componentsSeparatedByCharactersInSet:breaksCharacterSet];

	NSMutableArray *comments = [NSMutableArray array];
	static NSString * const kCommentPrefix = @"/*";
	static NSString * const kCommentSuffix = @"*/";

	for (__strong NSString *line in lines) {
		if ([line hasSuffix:@";"]) {
			line = [line substringWithRange:NSMakeRange(0, [line length]-1)];
		}
		NSArray *components = [line componentsSeparatedByString:@"\" = \""];
		if ([components count] == 2) {
			NSString *string = [components objectAtIndex:0];
			NSString *translation = [components objectAtIndex:1];
			if ([string hasPrefix:@"\""]) {
				string = [string substringWithRange:NSMakeRange(1, [string length]-1)];
				string = [string stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
			}
			if ([translation hasSuffix:@"\""]) {
				translation = [translation substringWithRange:NSMakeRange(0, [translation length]-1)];
				translation = [translation stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
			}
			NSMutableDictionary *object = [NSMutableDictionary dictionary];
			if (translation) { [object setObject:translation forKey:kTranslationKey]; }
			if (comments) { [object setObject:comments forKey:kCommentsKey]; }
			[strings setObject:object forKey:string];
			[order addObject:string];
			comments = [NSMutableArray array];
		}
		else if ([line hasPrefix:kCommentPrefix] && [line hasSuffix:kCommentSuffix]) {
			NSRange range = {};
			range.location = [kCommentPrefix length];
			range.length = [line length]-[kCommentPrefix length]-[kCommentSuffix length];
			NSString *substring = [line substringWithRange:range];
			[comments addObject:
			 [substring stringByTrimmingCharactersInSet:
			  [NSCharacterSet whitespaceCharacterSet]]];
		}
		else { comments = [NSMutableArray array]; }
	}
}

- (BOOL)writeToFile:(NSString *)path format:(FRStringsFormat)format error:(NSError **)error {
	if (format == FRStringsFormatPropertyList) {
		return [[self contentsInFormat:format] writeToFile:path atomically:YES];
	}
	else if (format == FRStringsFormatQuoted) {
		return [[self contentsInFormat:format] writeToFile:path atomically:YES
												  encoding:NSUTF8StringEncoding error:error];
	}
	else { return FALSE; }
}

- (id)contentsInFormat:(FRStringsFormat)format {
	if (format == FRStringsFormatPropertyList) {
		NSMutableDictionary *plist = [NSMutableDictionary dictionary];
		for (NSString *string in self) {
			NSString *translation = [self translationForString:string];
			if (translation) {
				[plist setObject:translation forKey:string];
			}
		}
		return plist;
	}
	else if (format == FRStringsFormatQuoted) {
		NSMutableString *result = [NSMutableString string];
		for (NSString *string in self) {
			NSArray *comments = [self commentsForString:string];
			NSString *translation = [self translationForString:string];
			
			if (translation) {
				for (NSString *comment in comments) {
					[result appendFormat:@"/* %@ */\n", comment];
				}
				NSString *escapedString = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
				NSString *escapedTranslation = [translation stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
				[result appendFormat:@"\"%@\" = \"%@\";\n\n", escapedString, escapedTranslation];
			}
		}
		return result;
	}
	else { return nil; }
}

- (NSUInteger)count {
	return [strings count];
}

- (NSString *)stringAtIndex:(NSUInteger)index {
	return [order objectAtIndex:index];
}

- (NSArray *)commentsForString:(NSString *)string {
	return [[strings objectForKey:string] objectForKey:kCommentsKey];
}

- (void)setComments:(NSArray *)comments forString:(NSString *)string {
	[[strings objectForKey:string] setObject:comments forKey:kCommentsKey];
}

- (NSString *)translationForString:(NSString *)string {
	return [[strings objectForKey:string] objectForKey:kTranslationKey];
}

- (void)setTranslation:(NSString *)translation forString:(NSString *)string {
	[[strings objectForKey:string] setObject:translation forKey:kTranslationKey];
}

- (NSEnumerator *)stringsEnumerator {
	return [order objectEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id *)stackbuf count:(NSUInteger)len {
	return [order countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end
