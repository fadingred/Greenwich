//
//  FRTranslator.h
//  Greenwich
//
//  Created by Benedict Fritz on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

@class 
	FRSingleNodeParsingDelegate, FRTranslateArrayResultParsingDelegate;

@interface FRTranslator : NSObject

@property (strong, nonatomic) NSString *authToken;
@property (strong, nonatomic) NSString *language;
@property (strong, nonatomic) FRSingleNodeParsingDelegate *singleNodeParser;
@property (strong, nonatomic) FRTranslateArrayResultParsingDelegate *translatedArrayParser;

- (NSArray *)translateArray:(NSArray *)arrayToTranslate;
- (NSString *)detectLanguageOfString:(NSString *)stringToDetect;

@end
