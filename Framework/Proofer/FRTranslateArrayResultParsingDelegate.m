//
//  FRTranslateArrayResultParsingDelegate.m
//  TestTranslate
//
//  Created by Benedict Fritz on 2/10/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "FRTranslateArrayResultParsingDelegate.h"

@implementation FRTranslateArrayResultParsingDelegate

@synthesize parsing;
@synthesize nextCharsAreTranslation;
@synthesize translations;

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	NSLog(@"Starting parse...");
	translations = [[NSMutableArray alloc] init];
	parsing = YES;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	NSLog(@"Ending parse...");
	NSLog(@"Translations: %@", translations);
	parsing = NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	if ([elementName isEqualToString:@"TranslatedText"]) { nextCharsAreTranslation = YES; }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (nextCharsAreTranslation) {
		[translations addObject:string];
		nextCharsAreTranslation = NO;
	}
}

@end
