//
//  FRTranslateArrayResultParsingDelegate.h
//  TestTranslate
//
//  Created by Benedict Fritz on 2/10/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FRTranslateArrayResultParsingDelegate : NSObject <NSXMLParserDelegate>

@property (nonatomic) BOOL parsing;
@property (nonatomic) BOOL nextCharsAreTranslation;
@property (strong, nonatomic) NSMutableArray *translations;

@end
