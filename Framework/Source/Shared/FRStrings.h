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

#import <Foundation/Foundation.h>

enum {
	FRStringsFormatQuoted,
	FRStringsFormatPropertyList,
};
typedef NSUInteger FRStringsFormat;

@interface FRStrings : NSObject <NSFastEnumeration> {
	NSMutableDictionary *strings;
	NSMutableArray *order;
}

/*!
 \brief		Create a new strings file
 \details	Create with the contents of a path
 */
- (id)initWithContentsOfFile:(NSString *)path usedFormat:(FRStringsFormat *)format error:(NSError **)error;

/*!
 \brief		Create a new strings file
 \details	Create with the given data
 */
- (id)initWithData:(NSData *)data usedFormat:(FRStringsFormat *)format error:(NSError **)error;

/*!
 \brief		Write the strings file
 \details	Write the stings file in the given format
 */
- (BOOL)writeToFile:(NSString *)path format:(FRStringsFormat)format error:(NSError **)error;

/*!
 \brief		Get the contents in a given format
 \details	Gets the contents in the given format. Each format will return different type of object:
				- FRStringsFormatQuoted: NSString
				- FRStringsFormatPropertyList: NSDictionary
 */
- (id)contentsInFormat:(FRStringsFormat)format;

/*!
 \brief		Enumerate the strings
 \details	Enumerate the strings (in order if possible)
 */
- (NSEnumerator *)stringsEnumerator;

/*!
 \brief		Count of strings
 \details	Count of strings
 */
- (NSUInteger)count;

/*!
 \brief		String at index
 \details	String at index
 */
- (NSString *)stringAtIndex:(NSUInteger)index;

/*!
 \brief		Comments for a string
 \details	Comments for a string
 */
- (NSArray *)commentsForString:(NSString *)string;

/*!
 \brief		Set comments for a string
 \details	Set comments for a string
 */
- (void)setComments:(NSArray *)comment forString:(NSString *)string;

/*!
 \brief		Translation for a string
 \details	Translation for a string
 */
- (NSString *)translationForString:(NSString *)string;

/*!
 \brief		Set translation for a string
 \details	Set translation for a string
 */
- (void)setTranslation:(NSString *)translation forString:(NSString *)string;

@end
