//
//  FRTranslator.h
//  Greenwich
//
//  Created by Benedict Fritz on 1/27/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

@class FRSingleNodeParsingDelegate;

@interface FRTranslator : NSObject

@property (strong, nonatomic) NSString *language;
@property (strong, nonatomic) FRSingleNodeParsingDelegate *singleNodeParser;

- translateString:(NSString *)stringToTranslate;
- (NSString *)detectLanguageOfString:(NSString *)stringToDetect;

@end
