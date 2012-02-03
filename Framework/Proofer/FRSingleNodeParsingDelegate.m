//
//  FRSingleNodeParsingDelegate.m
//  TestTranslate
//
//  Created by Benedict Fritz on 1/13/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "FRSingleNodeParsingDelegate.h"

@implementation FRSingleNodeParsingDelegate

@synthesize result;

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	self.result = string;
}

@end
