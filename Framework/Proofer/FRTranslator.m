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

#import "FRTranslator.h"
#import "FRSingleNodeParsingDelegate.h"
#import "FRTranslateArrayResultParsingDelegate.h"

static NSString *kErrorString = @"Error!";

@interface FRTranslator ()
- (NSString *)escapeString:(NSString *)string;
@end

@implementation FRTranslator

@synthesize clientId;
@synthesize clientSecret;
@synthesize authToken;
@synthesize language;
@synthesize singleNodeParser;
@synthesize translatedArrayParser;

- (id)init {
	if (self = [super init]) {
		self.language = NULL;
		self.singleNodeParser = [[FRSingleNodeParsingDelegate alloc] init];
		self.translatedArrayParser = [[FRTranslateArrayResultParsingDelegate alloc] init];
	}
	return self;
}

- (BOOL)getAccessToken {
	NSString *accessURI = @"https://datamarket.accesscontrol.windows.net/v2/OAuth2-13";
	NSString *requestString = [NSString stringWithFormat:@"grant_type=client_credentials&client_id=%@&client_secret=%@&scope=http://api.microsofttranslator.com", 
							   [self escapeString:self.clientId], [self escapeString:self.clientSecret]];
	
	NSURL *url = [NSURL URLWithString:accessURI];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData
													   timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:[requestString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	// don't want to use a JSON parser when all I'm really doing is pulling out this one piece of data
	NSArray *resultParts = [result componentsSeparatedByString:@"\""];
	self.authToken = [resultParts objectAtIndex:3];

	BOOL success = TRUE;
	if ([self.authToken isEqualToString:@"invalid_client"]) {
		success = FALSE;
	}
	return success;
}

- (NSArray *)translateArray:(NSArray *)arrayToTranslate {
	NSMutableString *urlString = [NSMutableString stringWithString:
								  @"http://api.microsofttranslator.com/v2/Http.svc/TranslateArray"];
	NSMutableString *dataString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:
		@"<TranslateArrayRequest>"
			@"<AppId />"
			@"<From>%@</From>"
			@"<Texts>", self.language]];

	for (NSString *string in arrayToTranslate) {
		NSString *startElement = @"<string xmlns=\"http://schemas.microsoft.com/2003/10/Serialization/Arrays\">";
		NSString *closeElement = @"</string>";
		[dataString appendFormat:@"%@%@%@", startElement, string, closeElement];
	}
	
	[dataString appendString:
			@"</Texts>"
			@"<To>en</To>"
		@"</TranslateArrayRequest>"];
	
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData
													   timeoutInterval:60.0];
	
	NSString *authHeader = [NSString stringWithFormat:@"Bearer %@", self.authToken];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
	[request addValue:authHeader forHTTPHeaderField:@"Authorization"];
	[request setHTTPBody:[dataString dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSURLResponse *response;
	NSError *error;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	if (data == nil) { NSLog(@"Could not parse translation result :["); }
	else {
		NSXMLParser *resultParser = [[NSXMLParser alloc] initWithData:data];
		resultParser.delegate = translatedArrayParser;
		[resultParser parse];
		while ([translatedArrayParser parsing]) { /* wait until the translation has been parsed */ }
	}

	return translatedArrayParser.translations;
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
