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

#import "FRProofer.h"
#import "FRTranslator.h"

@interface FRProofer ()
- (NSString *)mostUsedLanguageFromArray:(NSArray *)languagesArray;
@end

@implementation FRProofer

@synthesize translator;

- (void)setClientId:(NSString *)clientId clientSecret:(NSString *)clientSecret {
	if (!self.translator) {
		self.translator = [[FRTranslator alloc] init];
	}
	self.translator.clientId = clientId;
	self.translator.clientSecret = clientSecret;
}

- (BOOL)setupAccessToken {
	return [self.translator getAccessToken];
}

- (void)proofFileFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
	NSError *error = nil;
	NSStringEncoding encoding;

	NSString *contents = [NSString stringWithContentsOfFile:fromPath
											   usedEncoding:&encoding
													  error:&error];

	NSArray *lines = [contents componentsSeparatedByCharactersInSet:
					  [NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];;

	if (!self.translator.language) {
		[self determineTranslatorLanguageUsingLines:lines];
	}

	NSMutableArray *originalStrings = [[NSMutableArray alloc] init];
	NSMutableArray *translatedStrings = [[NSMutableArray alloc] init];

	for (NSString *line in lines) {
		NSUInteger location = [line rangeOfString:@"/*"].location;
		if (location == NSNotFound && [line length] != 0) {
			[originalStrings addObject:[self leftSideOfStringsLine:line]];
			[translatedStrings addObject:[self rightSideOfStringsLine:line]];
		}
	}
	NSArray *proofedStrings = [translator translateArray:translatedStrings];
	
	NSString *outputString = @"/* Translation = Original = Proofed */\n";
	for (NSUInteger i = 0; i < [originalStrings count]; i++) {
		outputString = [outputString stringByAppendingFormat:@"\"%@\" = \"%@\" = \"%@\"\n", 
						[translatedStrings objectAtIndex:i], [originalStrings objectAtIndex:i], 
						[proofedStrings objectAtIndex:i]];
	}

	[outputString writeToFile:toPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];	
}

- (void)determineTranslatorLanguageUsingLines:(NSArray *)lines {
	if (!self.translator) { self.translator = [[FRTranslator alloc] init]; }

	// each translation takes up three lines. check the language of the first 5 lines to determine which language to
	// translate from
	NSArray *firstLines;
	if ([lines count] > 15) {
		NSRange firstTenLinesRange = { .location = 0, .length = 15 };
		firstLines = [lines subarrayWithRange:firstTenLinesRange];
	}
	else {
		firstLines = lines;
	}
	
	NSMutableArray *detectedLanguages = [[NSMutableArray alloc] init];
	for (NSString *line in firstLines) {
		NSString *translatedStringInLine = [self rightSideOfStringsLine:line];
		if (![translatedStringInLine isEqualToString:@""]) {
			NSString *detectedLanguage = [self.translator detectLanguageOfString:translatedStringInLine];
			[detectedLanguages addObject:detectedLanguage];
		}
	}

	self.translator.language = [self mostUsedLanguageFromArray:detectedLanguages];
}

- (NSString *)mostUsedLanguageFromArray:(NSArray *)languagesArray {
	NSMutableDictionary *languagesDict = [[NSMutableDictionary alloc] init];
	for (NSString *language in languagesArray) {
		[self incrementOccurrenceCountOfLanguage:language InDict:languagesDict];
	}

	NSString *mostUsedLanguage = [self mostUsedLanguageInDictionary:languagesDict];
	return mostUsedLanguage;
}

- (void)incrementOccurrenceCountOfLanguage:(NSString *)language InDict:(NSMutableDictionary *)languagesDict {
	NSNumber *numInstancesOfLanguage = [languagesDict objectForKey:language];
	if (numInstancesOfLanguage) {
		int intValue = [numInstancesOfLanguage intValue];
		intValue++;
		numInstancesOfLanguage = [NSNumber numberWithInt:intValue];
		[languagesDict setObject:numInstancesOfLanguage forKey:language];
	}
	else {
		[languagesDict setValue:[NSNumber numberWithInt:1] forKey:language];
	}
}

- (NSString *)mostUsedLanguageInDictionary:(NSDictionary *)dictionary {
	NSEnumerator *langEnumerator = [dictionary keyEnumerator];
	NSString *mostUsedLang = @"";
	NSNumber *mostOccurrences = [NSNumber numberWithInt:0];

	NSString *lang; 
	while (lang = [langEnumerator nextObject]) {
		NSNumber *occurrencesOfLang = [dictionary valueForKey:lang];
		if ([occurrencesOfLang compare:mostOccurrences] == NSOrderedDescending) {
			mostUsedLang = lang;
			mostOccurrences = occurrencesOfLang;
		}
	}
	return mostUsedLang;
}

- (NSString *)leftSideOfStringsLine:(NSString *)line {
	NSString *leftSide = @"";
	NSArray *components = [line componentsSeparatedByString:@"\" = \""];
	NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"\";"];
	if ([components count] == 2) {
			leftSide = [[components objectAtIndex:0] stringByTrimmingCharactersInSet:trim];
	}
	return leftSide;
}

- (NSString *)rightSideOfStringsLine:(NSString *)line {
	NSString *rightSide = @"";
	NSArray *components = [line componentsSeparatedByString:@"\" = \""];
	if ([components count] == 2) {
		NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"\";"];
		rightSide = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:trim];
	}
	return rightSide;
}

@end
