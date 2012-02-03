//
//  AppDelegate.h
//  Proofer
//
//  Created by Benedict Fritz on 1/20/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FRProofer;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSButton *proofButton;
@property (strong, nonatomic) IBOutlet NSTextField *pathTextField;
@property (strong, nonatomic) FRProofer *proofer;

@end
