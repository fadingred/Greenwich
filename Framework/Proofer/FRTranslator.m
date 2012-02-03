//
//  FRTranslator.m
//  Greenwich
//
//  Created by Benedict Fritz on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "FRTranslator.h"
#import "FRSingleNodeParsingDelegate.h"

static NSString *kErrorString = @"Error!";

@interface FRTranslator ()
- (NSString *)escapeString:(NSString *)string;
@end

@implementation FRTranslator

@synthesize language;
@synthesize singleNodeParser;

- (id)init {
	if (self = [super init]) {
		self.language = @"";
		self.singleNodeParser = [[FRSingleNodeParsingDelegate alloc] init];
	}
	return self;
}

- translateString:(NSString *)stringToTranslate {
	NSMutableString *translateFrom = [NSMutableString stringWithString:@"&from="];
	[translateFrom appendString:self.language];
	
	if ([translateFrom isEqualToString:kErrorString]) {
		NSLog(@"Couldn't detect language");
		return @"";
	}
	
	NSMutableString *urlString = [NSMutableString stringWithString:
								  @"http://api.microsofttranslator.com/v2/Http.svc/Translate?appId=AC56E0F30DC3119A55994244361E06DC1B777049&text="];
	
	NSString *escapedStringToTranslate = [self escapeString:stringToTranslate];
	[urlString appendString:escapedStringToTranslate];
	[urlString appendString:translateFrom];
	[urlString appendString:@"&to=en"];
	
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:60.0];
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (data == nil) { NSLog(@"Could not parse translation result :["); }
	else {
		NSXMLParser *resultParser = [[NSXMLParser alloc]initWithData:data];
		resultParser.delegate = singleNodeParser;
		[resultParser parse];
		
		while (![singleNodeParser result]) { /* wait until the translation has been parsed */ }
		
		return [singleNodeParser result];
	}
	
	return @"Error";
}

- (NSString *)detectLanguageOfString:(NSString *)stringToDetect {
	NSMutableString *urlString = 
	[NSMutableString stringWithString: 
	 @"http://api.microsofttranslator.com/v2/Http.svc/Detect?appId=AC56E0F30DC3119A55994244361E06DC1B777049&text="];
	
	NSString *escapedStringToTranslate = [self escapeString:stringToDetect];
	[urlString appendString:escapedStringToTranslate];
	
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData
										 timeoutInterval:60.0];
	
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (data == nil) {
		return kErrorString;
	}
	else {
		NSXMLParser *resultParser = [[NSXMLParser alloc]initWithData:data];
		resultParser.delegate = singleNodeParser;
		[resultParser parse];
		
		NSString *detectedLanguage;
		while (![singleNodeParser result]) {
			// wait until the language has been parsed
		}
		detectedLanguage = [singleNodeParser result];
		return detectedLanguage;
	}
}

- (NSString *)escapeString:(NSString *)string {
	CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																		(__bridge void *)string,
																		NULL,
																		(CFStringRef)@"!$&'()*+,-./:;=?@_~",
																		kCFStringEncodingUTF8);
	return (__bridge_transfer id)(escapedString);
}


@end
