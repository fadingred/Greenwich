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

#import <objc/runtime.h>
#import <dlfcn.h>

#import "FRUIAutomaticLocalization.h"
#import "FRRuntimeAdditions.h"
#import "FRLocalizationBundleAdditions.h"
#import "FRBundleAdditions.h"

static int FRAutomaticLocalizationBundleKey;
static int FRAutomaticLocalizationTableKey;

// we're making the assumption that all nibs are created on the main thread,
// so these variables don't need to be thread local or thread safe at all.
static NSString *gInitializingLocalizationTableKey;
static NSBundle *gInitializingLocalizationBundleKey;

static Class gWebViewClass = nil;

@interface UINib (FRNibAutomaticLocalizationPrivate)
- (BOOL)automaticallyLocalizes;
- (void)localizeObject:(id)object;
- (void)localizeTitle:(id)object;
- (void)localizeText:(id)object;
- (void)localizePlaceholder:(id)object;
- (void)localizePrompt:(id)object;
- (NSString *)localizedStringFor:(NSString *)string;
@end

// swizzling
static NSArray *(*SLoadNib)(id self, SEL _cmd, NSString *name, id owner, NSDictionary *options);
static NSArray *(FRLoadNib)(id self, SEL _cmd, NSString *name, id owner, NSDictionary *options);

@implementation NSBundle (FRNibAutomaticLocalization)

+ (void)load {
	[self swizzle:@selector(loadNibNamed:owner:options:) with:(IMP)FRLoadNib store:(IMPPointer)&SLoadNib];
}

static NSArray *FRLoadNib(id self, SEL _cmd, NSString *name, id owner, NSDictionary *options) {
	// allocate a nib and check if it automatically localizes.
	// if it does, load the nib with the owner and options.
	UINib *nib = [UINib nibWithNibName:name bundle:self];
	if ([nib automaticallyLocalizes]) {
		return [nib instantiateWithOwner:owner options:options];
	} else {
		return SLoadNib(self, _cmd, name, owner, options);
	}
}

@end


// swizzling
static UINib *(*SCreateNib)(id self, SEL _cmd, NSString *name, NSBundle *bundle);
static UINib *(FRCreateNib)(id self, SEL _cmd, NSString *name, NSBundle *bundle);
static id (*SInitNibWithCodder)(id self, SEL _cmd, NSCoder *coder);
static id (FRInitNibWithCodder)(id self, SEL _cmd, NSCoder *coder);
static NSArray *(*SInstantiateNib)(id self, SEL _cmd, id owner, NSDictionary *options);
static NSArray *(FRInstantiateNib)(id self, SEL _cmd, id owner, NSDictionary *options);

@implementation UINib (FRNibAutomaticLocalization)

+ (void)load {
	gWebViewClass = NSClassFromString(@"UIWebView");
	
	[self swizzleClassMethod:@selector(nibWithNibName:bundle:) with:(IMP)FRCreateNib store:(IMPPointer)&SCreateNib];
	[self swizzle:@selector(initWithCoder:) with:(IMP)FRInitNibWithCodder store:(IMPPointer)&SInitNibWithCodder];
	[self swizzle:@selector(instantiateWithOwner:options:)
			 with:(IMP)FRInstantiateNib store:(IMPPointer)&SInstantiateNib];
}

static UINib *FRCreateNib(id self, SEL _cmd, NSString *name, NSBundle *bundle) {
	UINib *result = SCreateNib(self, _cmd, name, bundle);
	
	BOOL localize = [bundle pathForResource:name ofType:@"strings"] != nil;

	// check to see this is a nib for a storyboard and there's a strings file with the name
	// of the storyboard. we're making the assumption that loading storyboard files will have
	// the name formatted as: StoryboardName.storyboardc/resource
	if (!localize) {
		NSArray *nameComponents = [name pathComponents];
		if ([nameComponents count]) {
			NSString *storyboardComponent = [nameComponents objectAtIndex:0];
			NSString *storyboardName = [storyboardComponent stringByDeletingPathExtension];
			NSString *storyboardExtension = [storyboardComponent pathExtension];
			if ([storyboardExtension isEqualToString:@"storyboardc"]) {
				name = storyboardName;
				localize = [bundle pathForResource:name ofType:@"strings"] != nil;
			}
		}
	}
	
	if (localize) {
		objc_setAssociatedObject(result, &FRAutomaticLocalizationBundleKey, bundle, OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(result, &FRAutomaticLocalizationTableKey, name, OBJC_ASSOCIATION_COPY);
	}
	
	return result;
}

static id FRInitNibWithCodder(id self, SEL _cmd, NSCoder *coder) {
	// nibs that are decoded while another nib is being initialized are considered part of that same table/bundle
	id result = SInitNibWithCodder(self, _cmd, coder);
	if ([NSThread isMainThread] && gInitializingLocalizationTableKey && gInitializingLocalizationBundleKey) {
		objc_setAssociatedObject(result, &FRAutomaticLocalizationBundleKey, gInitializingLocalizationBundleKey, OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(result, &FRAutomaticLocalizationTableKey, gInitializingLocalizationTableKey, OBJC_ASSOCIATION_COPY);
	}
	return result;
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
			if ([object isKindOfClass:[UIView class]]) {
				NSMutableSet *localizeSubviews = [NSMutableSet setWithArray:[object subviews]];
				
				if ([object isKindOfClass:[UILabel class]]) {
					[self localizeText:object];
				}
				else if ([object isKindOfClass:[UIButton class]]) {
					// as of right now, there's no way to set anything other than the
					// normal state title in interface builder
					NSString *title = [object titleForState:UIControlStateNormal];
					if (title) {
						[object setTitle:[self localizedStringFor:title] forState:UIControlStateNormal];
					}
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UINavigationBar class]]) {
					[self localizeObject:[object items]];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UIToolbar class]]) {
					[self localizeObject:[object items]];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UITabBar class]]) {
					[self localizeObject:[object items]];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UISearchBar class]]) {
					[self localizeText:object];
					[self localizePlaceholder:object];
					[self localizePrompt:object];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UITextField class]]) {
					[self localizeText:object];
					[self localizePlaceholder:object];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UITextView class]]) {
					[self localizeText:object];
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UISegmentedControl class]]) {
					for (NSUInteger i = 0; i < [object numberOfSegments]; i++) {
						NSString *title = [object titleForSegmentAtIndex:i];
						if (title) {
							[object setTitle:[self localizedStringFor:title] forSegmentAtIndex:i];
						}
					}
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UITableViewCell class]]) {
					// skip the content view, but handle its subviews
					UIView *contentView = [object contentView];
					[localizeSubviews addObjectsFromArray:[contentView subviews]];
					[localizeSubviews removeObject:contentView];
				}
				else if ([object isKindOfClass:[UIPickerView class]] ||
						 [object isKindOfClass:[UIDatePicker class]] ||
						 (gWebViewClass && [object isKindOfClass:[gWebViewClass class]])) {
					[localizeSubviews removeAllObjects];
				}
				else if ([object isKindOfClass:[UITableView class]] ||
						 [object isKindOfClass:[UIImageView class]] ||
						 [object isKindOfClass:[UIStepper class]] ||
						 [object isKindOfClass:[UISlider class]] ||
						 [object isKindOfClass:[UISlider class]] ||
						 [object isKindOfClass:[UISwitch class]] ||
						 [object isKindOfClass:[UIActivityIndicatorView class]] ||
						 [object isKindOfClass:[UIProgressView class]] ||
						 [object isKindOfClass:[UIPageControl class]] ||
						 [object isKindOfClass:[UIScrollView class]]) {
					// nothing to loacalize
				}
				else if ([object class] == [UIView class]) {
					// empty views have nothing to localize
				}
				else { unhandled = TRUE; }
				
				// localize subviews
				[self localizeObject:[localizeSubviews allObjects]];
			}
			else if ([object isKindOfClass:[UIBarItem class]]) {
				[self localizeTitle:object];
			}
			else if ([object isKindOfClass:[UINavigationItem class]]) {
				[self localizeTitle:object];
				[self localizePrompt:object];
				[self localizeObject:[object titleView]];
			}
			else if ([object isKindOfClass:[UINavigationController class]]) {
				[self localizeObject:[object viewControllers]];
				[self localizeObject:[object toolbar]];
				[self localizeObject:[object navigationBar]];
			}
			else if ([object isKindOfClass:[UITabBarController class]]) {
				[self localizeObject:[object viewControllers]];
				[self localizeObject:[object tabBar]];
			}
			else if ([object isKindOfClass:[UISplitViewController class]]) {
				[self localizeObject:[object viewControllers]];
			}
			else if ([object isKindOfClass:[UISearchDisplayController class]]) {
				if ([object searchResultsTitle]) {
					[object setSearchResultsTitle:
					 [self localizedStringFor:[object searchResultsTitle]]];
				}
			}
			else if ([object isKindOfClass:[UIViewController class]]) {
				// view controllers in storyboards will cause another nib to be loaded, so we
				// don't actually want to localize them right away. this is just one case where
				// this could happen, though. in every case, we still don't want to force the
				// controller to load the view right now. it will get localized when it's loaded
				// later.
				if ([object isViewLoaded]) {
					[self localizeObject:[object view]];
				}
				[self localizeObject:[object toolbarItems]];
				[self localizeObject:[object tabBarItem]];
				[self localizeObject:[object navigationItem]];
				[self localizeTitle:object];
			}
			else if ([object superclass] == [NSObject class] &&
					 [object conformsToProtocol:@protocol(UITableViewDataSource)]) {
				// we can localize static table view cells by handling the
				// custom delegate object that is created by interface builder
				NSInteger sections = 1;
				if ([object respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
					sections = [object numberOfSectionsInTableView:nil];
				}
				for (NSInteger section = 0; section < sections; section++) {
					for (NSInteger row = 0; row < [object tableView:nil numberOfRowsInSection:section]; row++) {
						[self localizeObject:
						 [object tableView:nil cellForRowAtIndexPath:
						  [NSIndexPath indexPathForRow:row inSection:section]]];
					}
				}
			}
			else if ([object superclass] == [NSObject class]) {
				// custom objects, nothing to localize
			}
			else if ([object isKindOfClass:[UIGestureRecognizer class]]) {
				// nothing to localize
			}
			else { unhandled = TRUE; }
			
			objc_setAssociatedObject(object, &FRIsLocalizedKey, [NSNumber numberWithBool:TRUE], OBJC_ASSOCIATION_RETAIN);
			
			if (unhandled) {
				BOOL private = [[[object class] description] hasPrefix:@"_"];
				if (!private) {
					BOOL (^isDefinedInSystemLibrary)(const char *) = ^BOOL(const char *path) {
						__autoreleasing NSString *string = [NSString stringWithUTF8String:path];
						NSRange range = [string rangeOfString:@"Developer/SDKs/"];
						if (range.location != NSNotFound) {
							range.location += range.length;
							range.length = [string length] - range.location;
							range = [string rangeOfString:@"/" options:0 range:range];
							if (range.location != NSNotFound) {
								path = [[string substringFromIndex:range.location] UTF8String];
							}
						}
						
						// check specific paths where we know xib items come from
						const char *kFoundationPrefix = "/System/Library/Frameworks/Foundation.framework/Foundation";
						static int foundationPrefixLength = 0;
						if (!foundationPrefixLength) { foundationPrefixLength = strlen(kFoundationPrefix); }
						const char *kAppKitPrefix = "/System/Library/Frameworks/UIKit.framework/UIKit";
						static int appKitPrefixLength = 0;
						if (!appKitPrefixLength) { appKitPrefixLength = strlen(kAppKitPrefix); }
						return
							(strncmp(path, kFoundationPrefix, foundationPrefixLength) == 0) ||
							(strncmp(path, kAppKitPrefix, appKitPrefixLength) == 0);
					};
					
					// check the location of method and warn if it is defined and the
					// definition is not located in the system frameworks
					Dl_info symbol_info = (Dl_info){};
					dladdr((__bridge void *)[object class], &symbol_info);
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

FRDefineLocalization(title, Title);
FRDefineLocalization(text, Text);
FRDefineLocalization(placeholder, Placeholder);
FRDefineLocalization(prompt, Prompt);

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

static NSArray *FRInstantiateNib(id self, SEL _cmd, id owner, NSDictionary *options) {
	NSString *currentTableKey = nil;
	NSBundle *currentBundleKey = nil;
	if ([NSThread isMainThread]) {
		NSString *instantiateTableKey = objc_getAssociatedObject(self, &FRAutomaticLocalizationTableKey);
		NSBundle *instantiateBundleKey = objc_getAssociatedObject(self, &FRAutomaticLocalizationBundleKey);
		currentTableKey = gInitializingLocalizationTableKey;
		currentBundleKey = gInitializingLocalizationBundleKey;
		if (instantiateTableKey && instantiateBundleKey) {
			gInitializingLocalizationTableKey = instantiateTableKey;
			gInitializingLocalizationBundleKey = instantiateBundleKey;
		}
	}
	
	NSArray *topLevelObjects = SInstantiateNib(self, _cmd, owner, options);
	
	if (topLevelObjects && [self automaticallyLocalizes]) {
		[self localizeObject:topLevelObjects];
	}
	
	if (topLevelObjects && [self automaticallyLocalizes]) {
		NSMutableSet *set = [NSMutableSet set];
		if (topLevelObjects) { [set addObjectsFromArray:topLevelObjects]; }
		if (owner) { [set addObject:owner]; }
		for (id object in set) {
			if ([object respondsToSelector:@selector(awakeFromLocalization)]) {
				static char kHasAwoken;
				if (![objc_getAssociatedObject(object, &kHasAwoken) boolValue]) {
					[object performSelector:@selector(awakeFromLocalization)];
					objc_setAssociatedObject(object, &kHasAwoken, [NSNumber numberWithBool:TRUE], OBJC_ASSOCIATION_RETAIN);
				}
			}
		}
	}
	
	if ([NSThread isMainThread]) {
		gInitializingLocalizationTableKey = currentTableKey;
		gInitializingLocalizationBundleKey = currentBundleKey;
	}
	return topLevelObjects;
}

@end

@implementation NSObject (FRNibAutomaticLocalization)
- (void)awakeFromLocalization { }
@end
