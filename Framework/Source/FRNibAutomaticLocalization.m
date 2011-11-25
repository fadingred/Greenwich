// 
// Copyright (c) 2011 FadingRed LLC
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

#import <objc/runtime.h>
#import <dlfcn.h>

#import "FRNibAutomaticLocalization.h"
#import "FRRuntimeAdditions.h"
#import "FRLocalizationBundleAdditions.h"
#import "FRBundleAdditions.h"

static int FRAutomaticLocalizationBundleKey;
static int FRAutomaticLocalizationTableKey;

static Class gTextFinderClass = nil;
static Class gPopoverClass = nil;

NSString * const FRContentValuesKey = @"contentValues";
NSString * const FRValueKey = @"value";

@interface NSNib (FRNibAutomaticLocalizationPrivate)
- (BOOL)automaticallyLocalizes;
- (void)localizeObject:(id)object;
- (void)localizeToolTip:(id)object;
- (void)localizeTitle:(id)object;
- (void)localizeAlternateTitle:(id)object;
- (void)localizeLabel:(id)object;
- (void)localizePaletteLabel:(id)object;
- (void)localizePlaceholderString:(id)object;
- (void)localizeStringValue:(id)object;
- (void)localizeContentValuesBinding:(id)object;
- (void)localizeColumnValueBinding:(NSTableColumn *)tc;
- (NSString *)localizedStringFor:(NSString *)string;
@end

// swizzling
static BOOL (*SLoadNibFile)(id self, SEL _cmd, NSString *fileName, NSDictionary *externalNameTable, NSZone *zone);
static BOOL (FRLoadNibFile)(id self, SEL _cmd, NSString *fileName, NSDictionary *externalNameTable, NSZone *zone);

@implementation NSBundle (FRNibAutomaticLocalization)

+ (void)load {
	gTextFinderClass = NSClassFromString(@"NSTextFinder");
	gPopoverClass = NSClassFromString(@"NSPopover");
	
	[self swizzleClassMethod:@selector(loadNibFile:externalNameTable:withZone:)
						with:(IMP)FRLoadNibFile
					   store:(IMPPointer)&SLoadNibFile];
}

static BOOL FRLoadNibFile(id self, SEL _cmd, NSString *fileName, NSDictionary *context, NSZone *zone) {
	// allocate a nib and check if it automatically localizes.
	// if it does, load the nib with the context table.
	NSNib *nib = [[[NSNib allocWithZone:zone] initWithContentsOfURL:[NSURL fileURLWithPath:fileName]] autorelease];
	if ([nib automaticallyLocalizes]) {
		return [nib instantiateNibWithExternalNameTable:context];
	} else {
		return SLoadNibFile(self, _cmd, fileName, context, zone);
	}
}

@end

// swizzling
static id (*SInitWithContents)(id self, SEL _cmd, NSURL *nibFileURL);
static id (FRInitWithContents)(id self, SEL _cmd, NSURL *nibFileURL);
static id (*SInitWithNib)(id self, SEL _cmd, NSString *nibName, NSBundle *bundle);
static id (FRInitWithNib)(id self, SEL _cmd, NSString *nibName, NSBundle *bundle);
static BOOL (*SInstantiateNib)(id self, SEL _cmd, NSDictionary *externalNameTable);
static BOOL (FRInstantiateNib)(id self, SEL _cmd, NSDictionary *externalNameTable);

@implementation NSNib (FRNibAutomaticLocalization)

+ (void)load {
	[self swizzle:@selector(initWithContentsOfURL:) with:(IMP)FRInitWithContents store:(IMPPointer)&SInitWithContents];
	[self swizzle:@selector(initWithNibNamed:bundle:) with:(IMP)FRInitWithNib store:(IMPPointer)&SInitWithNib];
	[self swizzle:@selector(instantiateNibWithExternalNameTable:)
			 with:(IMP)FRInstantiateNib
			store:(IMPPointer)&SInstantiateNib];
}

static id FRInitWithContents(id self, SEL _cmd, NSURL *nibFileURL) {
	if ((self = SInitWithContents(self, _cmd, nibFileURL))) {
		NSString *path = [nibFileURL path];
		NSString *directory = [path stringByDeletingLastPathComponent];
		NSString *nibName = [[path lastPathComponent] stringByDeletingPathExtension];
		NSBundle *bundle = [NSBundle bundleWithPath:directory]; // this may not be the exact right bundle, but it works
		BOOL localize = [bundle pathForResource:nibName ofType:@"strings"] != nil;
		if (localize) {
			objc_setAssociatedObject(self, &FRAutomaticLocalizationBundleKey, bundle, OBJC_ASSOCIATION_RETAIN);
			objc_setAssociatedObject(self, &FRAutomaticLocalizationTableKey, nibName, OBJC_ASSOCIATION_COPY);
		}
	}
	return self;
}

static id FRInitWithNib(id self, SEL _cmd, NSString *nibName, NSBundle *bundle) {
	if ((self = SInitWithNib(self, _cmd, nibName, bundle))) {
		BOOL localize = [bundle pathForResource:nibName ofType:@"strings"] != nil;
		if (localize) {
			objc_setAssociatedObject(self, &FRAutomaticLocalizationBundleKey, bundle, OBJC_ASSOCIATION_RETAIN);
			objc_setAssociatedObject(self, &FRAutomaticLocalizationTableKey, nibName, OBJC_ASSOCIATION_COPY);
		}
	}
	return self;
}

- (BOOL)automaticallyLocalizes {
	return objc_getAssociatedObject(self, &FRAutomaticLocalizationTableKey) != nil;
}

- (void)localizeObject:(id)object {
	if ([object isKindOfClass:[NSArray class]]) {
		for (id item in object) { [self localizeObject:item]; }
	} else if (object) {
		BOOL unhandled = FALSE;
		static int FRIsLocalizedKey;

		if (![objc_getAssociatedObject(object, &FRIsLocalizedKey) boolValue]) {
			if ([object isKindOfClass:[NSView class]]) {
				[self localizeObject:[object subviews]];
				[self localizeToolTip:object];
				
				if ([object isKindOfClass:[NSTableView class]]) {
					[self localizeObject:[object tableColumns]];
				}
				else if ([object isKindOfClass:[NSPathControl class]]) {
					// nothing to localize for this
				}
				else if ([object isKindOfClass:[NSTextField class]]) {
					// only localize a text field when it isn't bound
					if ([object infoForBinding:FRValueKey] == nil) {
						[self localizeObject:[object cell]];
					}
				}
				else if ([object isKindOfClass:[NSBox class]]) {
					[self localizeTitle:object];
				}
				else if ([object isKindOfClass:[NSTabView class]]) {
					[self localizeObject:[object tabViewItems]];
				}
				else if ([object isKindOfClass:[NSControl class]]) {
					if ([object isKindOfClass:[NSPopUpButton class]]) {
						if ([object infoForBinding:FRContentValuesKey]) {
							[self localizeContentValuesBinding:object];
						}
					}
					else if ([object isKindOfClass:[NSMatrix class]]) {
						for (NSInteger row = 0; row < [object numberOfRows]; row++) {
							for (NSInteger col = 0; col < [object numberOfColumns]; col++) {
								[self localizeObject:[object cellAtRow:row column:col]];
							}
						}
					}
					else if ([object class] == [NSButton class] ||
							 [object isKindOfClass:[NSScroller class]] ||
							 [object isKindOfClass:[NSImageView class]] ||
							 [object isKindOfClass:[NSSlider class]] ||
							 [object isKindOfClass:[NSStepper class]] ||
							 [object isKindOfClass:[NSSegmentedControl class]] ||
							 [object isKindOfClass:[NSLevelIndicator class]] ||
							 [object isKindOfClass:[NSDatePicker class]] ||
							 [object isKindOfClass:[NSColorWell class]] ||
							 [object isKindOfClass:[NSBrowser class]]) {
						// just the cell is enough
					}
					else { unhandled = TRUE; }
					
					[self localizeObject:[object cell]];
				}
				else if ([object isKindOfClass:[NSTextView class]]) {
					// don't want to localize this automatically. there's just too much
					// complexity that could occur during design time.
				}
				else if ([object isKindOfClass:[NSClipView class]] ||
						 [object isKindOfClass:[NSScrollView class]] ||
						 [object isKindOfClass:[NSSplitView class]] ||
						 [object isKindOfClass:[NSTableHeaderView class]] ||
						 [object isKindOfClass:[NSProgressIndicator class]] ||
						 [object isKindOfClass:[NSCollectionView class]] ||
						 [object isKindOfClass:[NSOpenGLView class]]) {
					// these views have nothing to localize
				}
				else if ([object class] == [NSView class]) {
					// empty views have nothing to localize
				}
				else { unhandled = TRUE; }
			}
			else if ([object isKindOfClass:[NSMenu class]]) {
				[self localizeObject:[object itemArray]];
				[self localizeTitle:object];
			}
			else if ([object isKindOfClass:[NSMenuItem class]]) {
				[self localizeObject:[object submenu]];
				[self localizeObject:[object view]];
				[self localizeTitle:object];
				[self localizeToolTip:object];
			}
			else if ([object isKindOfClass:[NSWindow class]]) {
				[self localizeObject:[object contentView]];
				[self localizeObject:[object toolbar]];
				[self localizeTitle:object];
			}
			else if ([object isKindOfClass:[NSToolbar class]]) {
				[self localizeObject:[object items]];
			}
			else if ([object isKindOfClass:[NSToolbarItem class]]) {
				[self localizeObject:[object view]];
				[self localizeToolTip:object];
				[self localizeLabel:object];
				[self localizePaletteLabel:object];
			}
			else if ([object isKindOfClass:[NSTableColumn class]]) {
				if ([object infoForBinding:FRValueKey]) {
					[self localizeColumnValueBinding:object];
				}
				[self localizeObject:[object headerCell]];
				[self localizeObject:[[object dataCell] menu]];
			}
			else if ([object isKindOfClass:[NSCell class]] &&
					   [object infoForBinding:FRValueKey] == nil) {
				if ([(NSCell *)object type] == NSTextCellType &&
					[(NSCell *)object isKindOfClass:[NSImageCell class]] == FALSE) {
					[self localizeStringValue:object];
				}
				if ([object isKindOfClass:[NSTextFieldCell class]]) {
					[self localizePlaceholderString:object];
				}
				else if ([object isKindOfClass:[NSPopUpButtonCell class]]) {
					[self localizeObject:[object menu]];
				}
				else if ([object isKindOfClass:[NSFormCell class]]) {
					[self localizeTitle:object];
				}
				else if ([object isKindOfClass:[NSSegmentedCell class]]) {
					for (NSInteger idx = 0; idx < [object segmentCount]; idx++) {
						NSString *label = [object labelForSegment:idx];
						NSString *localized = [self localizedStringFor:label];
						[object setLabel:localized forSegment:idx];
					}
				}
				else if ([object isKindOfClass:[NSButtonCell class]]) {
					[self localizeTitle:object];
					// shouldn't we be able to do this?
					// what's going on with some of the buttons?
					// come back to this next time! :)
					//[self localizeAlternateTitle:object];
				}
				else if ([object isKindOfClass:[NSImageCell class]] ||
						 [object isKindOfClass:[NSDatePickerCell class]] ||
						 [object isKindOfClass:[NSStepperCell class]] ||
						 [object isKindOfClass:[NSLevelIndicatorCell class]] ||
						 [object isKindOfClass:[NSSliderCell class]]) {
					// nothing to localize
				}
				else { unhandled = TRUE; }
			}
			else if ([object isKindOfClass:[NSTabViewItem class]]) {
				[self localizeLabel:object];
			}
			else if ([object isKindOfClass:[NSApplication class]] ||
					 [object isKindOfClass:[NSFontManager class]] ||
					 [object isKindOfClass:[NSDrawer class]] ||
					 [object isKindOfClass:[NSFormatter class]] ||
					 [object isKindOfClass:[NSViewController class]] ||
					 [object isKindOfClass:[NSObjectController class]] ||
					 [object isKindOfClass:[NSUserDefaultsController class]] ||
					 (gTextFinderClass && [object isKindOfClass:[gTextFinderClass class]]) ||
					 (gPopoverClass && [object isKindOfClass:[gPopoverClass class]]) ) {
				// these objects have nothing to localize
			}
			else { unhandled = TRUE; }
			
			objc_setAssociatedObject(object, &FRIsLocalizedKey, [NSNumber numberWithBool:TRUE], OBJC_ASSOCIATION_RETAIN);
			
			if (unhandled) {
				BOOL private = [[[object class] description] hasPrefix:@"_"];
				if (!private) {
					BOOL (^isDefinedInSystemLibrary)(const char *) = ^BOOL(const char *path) {
						// check specific paths where we know xib items come from
						const char *kFoundationPrefix = "/System/Library/Frameworks/Foundation.framework";
						static int foundationPrefixLength = 0;
						if (!foundationPrefixLength) { foundationPrefixLength = strlen(kFoundationPrefix); }
						const char *kAppKitPrefix = "/System/Library/Frameworks/AppKit.framework";
						static int appKitPrefixLength = 0;
						if (!appKitPrefixLength) { appKitPrefixLength = strlen(kAppKitPrefix); }
						return
							(strncmp(path, kFoundationPrefix, foundationPrefixLength) == 0) ||
							(strncmp(path, kAppKitPrefix, appKitPrefixLength) == 0);
					};

					// check the location of method and warn if it is defined and the
					// definition is not located in the system frameworks
					Dl_info symbol_info = (Dl_info){};
					dladdr([object class], &symbol_info);
					if (isDefinedInSystemLibrary(symbol_info.dli_fname)) {
						NSLog(@"Greenwich could not localize an instance of type %@. "
							  @"Please file an enhancement request at: "
							  @"https://github.com/fadingred/Greenwich", [object class]);
					}
				}
			}
		}
	}
}

#define FRDefineLocalization(lowSignature, upSignature) \
- (void)localize ## upSignature:(id)object { \
	if ([object lowSignature]) { \
		[object set ## upSignature: \
		 [self localizedStringFor:[object lowSignature]]]; \
	} \
}

FRDefineLocalization(toolTip, ToolTip);
FRDefineLocalization(title, Title);
FRDefineLocalization(alternateTitle, AlternateTitle);
FRDefineLocalization(label, Label);
FRDefineLocalization(paletteLabel, PaletteLabel);
FRDefineLocalization(placeholderString, PlaceholderString);
FRDefineLocalization(stringValue, StringValue);

- (NSString *)localizedStringFor:(NSString *)string {
	if (string && [string length]) {
		NSBundle *bundle = objc_getAssociatedObject(self, &FRAutomaticLocalizationBundleKey);
		NSString *table = objc_getAssociatedObject(self, &FRAutomaticLocalizationTableKey);
		
		// since the bundle isn't the real bundle, we need to keep moving up through the
		// path to try to find the identifier.
		NSString *directory = [bundle bundlePath];
		while (([[directory pathComponents] count] > 1)) {
			NSBundle *check = [NSBundle bundleWithPath:directory];
			directory = [directory stringByDeletingLastPathComponent];
			if ([check bundleIdentifier]) {
				bundle = check;
				break;
			}
		}

		return [bundle localizedStringForKey:string value:string table:table];
	} else {
		return string;
	}
}

- (void)localizeContentValuesBinding:(id)object {
	// store the current binding values
	NSDictionary *cvBinding = [object infoForBinding:FRContentValuesKey];
	NSString *observedKeyPath = [cvBinding objectForKey:NSObservedKeyPathKey];
	id observedObject = [cvBinding objectForKey:NSObservedObjectKey];
	
	// translate the placeholder strings
	NSMutableDictionary *newOptions = [[[cvBinding objectForKey:NSOptionsKey] mutableCopy] autorelease];
	NSString *multipleValuesPlaceholder = [newOptions valueForKey:NSMultipleValuesPlaceholderBindingOption];
	NSString *noSelectionPlaceholder = [newOptions valueForKey:NSNoSelectionPlaceholderBindingOption];
	NSString *notApplicablePlaceholder = [newOptions valueForKey:NSNotApplicablePlaceholderBindingOption];
	NSString *nullPlaceholder = [newOptions valueForKey:NSNullPlaceholderBindingOption];
	
	if (multipleValuesPlaceholder != (id)[NSNull null] && [multipleValuesPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:multipleValuesPlaceholder]
					   forKey:NSMultipleValuesPlaceholderBindingOption];
	}
	if (noSelectionPlaceholder != (id)[NSNull null] && [noSelectionPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:noSelectionPlaceholder]
					   forKey:NSNoSelectionPlaceholderBindingOption];
	}
	if (notApplicablePlaceholder != (id)[NSNull null] && [notApplicablePlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:notApplicablePlaceholder]
					   forKey:NSNotApplicablePlaceholderBindingOption];
	}
	if (nullPlaceholder != (id)[NSNull null] && [nullPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:nullPlaceholder]
					   forKey:NSNullPlaceholderBindingOption];
	}
	
	// unbind then rebind using the new translation values
	[object unbind:FRContentValuesKey];
	[object bind:FRContentValuesKey
		toObject:observedObject
	 withKeyPath:observedKeyPath
		 options:(NSDictionary *)newOptions];
}

- (void)localizeColumnValueBinding:(NSTableColumn *)tc {
	// store the value binding
	NSDictionary *vBinding = [tc infoForBinding:FRValueKey];
	NSString *observedKeyPath = [vBinding objectForKey:NSObservedKeyPathKey];
	id observedObject = [vBinding objectForKey:NSObservedObjectKey];
	
	// translate the placeholder strings
	NSMutableDictionary *newOptions = [[[vBinding objectForKey:NSOptionsKey] mutableCopy] autorelease];
	NSString *multipleValuesPlaceholder = [newOptions valueForKey:NSMultipleValuesPlaceholderBindingOption];
	NSString *noSelectionPlaceholder = [newOptions valueForKey:NSNoSelectionPlaceholderBindingOption];
	NSString *notApplicablePlaceholder = [newOptions valueForKey:NSNotApplicablePlaceholderBindingOption];
	NSString *nullPlaceholder = [newOptions valueForKey:NSNullPlaceholderBindingOption];
	
	if (multipleValuesPlaceholder != (id)[NSNull null] && [multipleValuesPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:multipleValuesPlaceholder]
					   forKey:NSMultipleValuesPlaceholderBindingOption];
	}
	if (noSelectionPlaceholder != (id)[NSNull null] && [noSelectionPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:noSelectionPlaceholder]
					   forKey:NSNoSelectionPlaceholderBindingOption];
	}
	if (notApplicablePlaceholder != (id)[NSNull null] && [notApplicablePlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:notApplicablePlaceholder]
					   forKey:NSNotApplicablePlaceholderBindingOption];
	}
	if (nullPlaceholder != (id)[NSNull null] && [nullPlaceholder length]) {
		[newOptions setObject:[self localizedStringFor:nullPlaceholder]
					   forKey:NSNullPlaceholderBindingOption];
	}
	
	// unbind then rebind using the new translation values
	[tc unbind:FRValueKey];
	[tc bind:FRValueKey
		toObject:observedObject
	 withKeyPath:observedKeyPath
		 options:(NSDictionary *)newOptions];
}

static BOOL FRInstantiateNib(id self, SEL _cmd, NSDictionary *externalNameTable) {
	id nameTable = externalNameTable;
	if (![externalNameTable objectForKey:NSNibTopLevelObjects]) {
		nameTable = [[externalNameTable mutableCopy] autorelease];
		[(NSMutableDictionary *)nameTable setObject:[NSMutableArray array] forKey:NSNibTopLevelObjects];
	}

	BOOL result = SInstantiateNib(self, _cmd, nameTable);

	if (result && [self automaticallyLocalizes]) {
		[self localizeObject:
		 [nameTable objectForKey:NSNibTopLevelObjects]];
	}

	if (result && [self automaticallyLocalizes]) {
		NSMutableSet *set = [NSMutableSet set];
		NSArray *topLevel = [nameTable objectForKey:NSNibTopLevelObjects];
		NSObject *owner = [externalNameTable objectForKey:NSNibOwner];
		if (topLevel) { [set addObjectsFromArray:topLevel]; }
		if (owner) { [set addObject:owner]; }
		for (id object in set) {
			if ([object respondsToSelector:@selector(awakeFromLocalization)]) {
				[object performSelector:@selector(awakeFromLocalization)];
			}
		}
	}
	
	return result;
}

@end
