//
//  AppDelegate.m
//  Proofer
//
//  Created by Benedict Fritz on 1/20/12.
//  Copyright (c) 2012 FadingRed. All rights reserved.
//

#import "AppDelegate.h"
#import "FRFileManagerArchivingAdditions.h"
#import "FRProofer.h"
#import "FRBundleAdditions.h"

@interface AppDelegate ()
- (void)importFromTbz:(NSString *)path toPath:(NSString *)exportPath;
- (void)importFromStringsFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath;
- (BOOL)validateInputs;
- (void)presentSavePanel;
@end

@implementation AppDelegate

@synthesize window;
@synthesize clientIdField;
@synthesize clientSecretField;
@synthesize proofButton;
@synthesize pathTextField;
@synthesize proofer;

- (IBAction)openFile:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setTitle:@"Import"];
	[openPanel setPrompt:@"Choose"];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"tbz", nil]];
	int returnCode = [openPanel runModal];
	if (returnCode == NSOKButton) {
		self.pathTextField.stringValue = [[[openPanel URLs] lastObject] path];
	}
}

- (IBAction)proof:(id)sender {
	// we make a new proofer every time in case they're doing a different file with a different language
	BOOL validInputs = [self validateInputs];
	self.proofer = [[FRProofer alloc] init];
	[self.proofer setClientId:clientIdField.stringValue clientSecret:clientSecretField.stringValue];
	
	BOOL validCredentials = [self.proofer setupAccessToken];
	if (!validCredentials) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid Credentials" defaultButton:nil 
									   alternateButton:@"Cancel" otherButton:nil 
							 informativeTextWithFormat:@"The Client ID and Client Secret entere were not recognized by the translation server as valid."];
		[alert runModal];
	}
	
	if (validInputs && validCredentials) { [self presentSavePanel]; }
}

- (BOOL)validateInputs {
	BOOL valid = YES;
	NSMutableString *errorString = [NSMutableString stringWithString:@""];
	
	NSString *inputFileExtension = [pathTextField.stringValue pathExtension];
	if (![inputFileExtension isEqualToString:@"tbz"]) {
		[errorString appendFormat:@"Please select a valid tbz file to proof.\n"];
		valid = NO;
	}
	
	if ([clientIdField.stringValue length] == 0 || clientIdField.stringValue == NULL) {
		valid = NO; 
		[errorString appendFormat:@"Please enter a registered client ID.\n"];
	}

	if ([clientSecretField.stringValue length] == 0 || clientSecretField.stringValue == NULL) { 
		valid = NO; 
		[errorString appendFormat:@"Please enter a registered client secret.\n"];
	}
	
	if (!valid) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:nil 
									   alternateButton:@"Cancel" otherButton:nil 
							 informativeTextWithFormat:errorString];
		[alert runModal];
	}
	
	return valid;
}

- (void)presentSavePanel {
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setTitle:FRLocalizedString(@"Export Location", nil)];
	[panel setMessage:FRLocalizedString(@"Please choose a location to save your proofed files.", nil)];
	[panel setPrompt:FRLocalizedString(@"Proof", nil)];
	[panel setExtensionHidden:TRUE];
	[panel setDirectoryURL:[NSURL fileURLWithPath:[@"~/Desktop" stringByExpandingTildeInPath]]];
	[panel setNameFieldStringValue:@"translation"];
	
	void (^completion)(NSInteger) = ^(NSInteger returnCode) {
		NSString *savePath = [[panel URL] path];
		[self importFromTbz:self.pathTextField.stringValue toPath:savePath];
	};
	
	[panel beginSheetModalForWindow:[self window] completionHandler:completion];
}

- (void)importFromTbz:(NSString *)path toPath:(NSString *)savePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;

	NSString *exportPath = [[self newTempDir] stringByAppendingPathComponent:@"extracted"];
	[fileManager uncompressItemAtPath:path to:exportPath error:&error];
	//TODO: implement proper error handling, especially in the case that the directory already exists
	if (error) { NSLog(@"Error"); }
	
	[fileManager createDirectoryAtPath:savePath withIntermediateDirectories:NO attributes:nil error:nil];
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:exportPath];
	NSString *filePath;
	while (filePath = [dirEnum nextObject]) {
		NSString *dirPath = [filePath stringByDeletingLastPathComponent];
		NSString *newFileDirPath = [savePath stringByAppendingPathComponent:dirPath];
		if (![fileManager contentsOfDirectoryAtPath:newFileDirPath error:nil]) {
			NSLog(@"Creating %@", newFileDirPath);
			[fileManager createDirectoryAtPath:newFileDirPath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		NSString *newFilePath = [savePath stringByAppendingPathComponent:filePath];
		NSString *fullFilePath = [exportPath stringByAppendingPathComponent:filePath];
		if ([[filePath pathExtension] isEqualToString:@"strings"]) {
			[self importFromStringsFileAtPath:fullFilePath toPath:newFilePath];
		}
	}
	[fileManager removeItemAtPath:[exportPath stringByDeletingLastPathComponent] error:NULL];
}

- (NSString *)newTempDir {
	NSString *tempDirectory = NSTemporaryDirectory();
	char *dirname = NULL;
	asprintf(&dirname, "%sPROOF_TEMP.XXXXX", [tempDirectory fileSystemRepresentation]);
	char *chdir_location = mkdtemp(dirname);
	
	if (!chdir_location) {
		NSLog(@"Temp directory creation failed.");
	}
	
	tempDirectory = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:chdir_location
																				length:strlen(chdir_location)];
	return tempDirectory;
}


- (void)importFromStringsFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
	[self.proofer proofFileFromPath:fromPath toPath:toPath];
}

@end
