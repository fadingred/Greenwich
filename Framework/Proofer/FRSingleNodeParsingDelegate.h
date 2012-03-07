//
//  FRSingleNodeParsingDelegate.h
//  TestTranslate
//
//  Created by Benedict Fritz on 1/13/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FRSingleNodeParsingDelegate : NSObject <NSXMLParserDelegate>

@property (strong, nonatomic) NSString *result;

@end
