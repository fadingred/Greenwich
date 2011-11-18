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

#ifndef REDLINKED_EXTRAHELPCONTROLLER

#import <objc/runtime.h>
#import <Carbon/Carbon.h>

#import "FRExtraHelpController.h"

@interface FRHelpMenuNotifyingDelegate : NSProxy {
@private
    id delegate;
}
+ (id)delegateWithOriginal:(id)delegate;
@end

@interface FRExtraHelpController (Pirvate)
- (void)_modifierFlagsChanged;
@end

CGEventRef flagsChanged(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon);
CGEventRef flagsChanged(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
	[[FRExtraHelpController defaultController] _modifierFlagsChanged];
	return NULL;
}

@implementation FRExtraHelpController

+ (id)defaultController {
	static FRExtraHelpController *defaultController = nil;
	if (defaultController == nil) {
		@synchronized(self) {
			if (defaultController == nil) {
				defaultController = [[self alloc] init];
			}
		}
	}
	return defaultController;
}

- (id)init {
	if ((self = [super init])) {
		separator = [[NSMenuItem separatorItem] retain];
		items = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[separator release];
	[items release];
	if (eventTap) { CFRelease(eventTap); }
	if (runLoopSource) { CFRelease(runLoopSource); }
	[super dealloc];
}

- (void)finalize {
	if (eventTap) { CFRelease(eventTap); }
	if (runLoopSource) { CFRelease(runLoopSource); }
	[super finalize];
}


#pragma mark -
#pragma mark installation
// ----------------------------------------------------------------------------------------------------
// installation
// ----------------------------------------------------------------------------------------------------

- (void)install {
	NSMenuItem *helpItem = [[[NSApp mainMenu] itemArray] lastObject];
	NSMenu *helpMenu = [helpItem submenu];
	id delegate = [FRHelpMenuNotifyingDelegate delegateWithOriginal:[helpMenu delegate]];
	[helpMenu setDelegate:delegate];

	// we need to retain the notifying delegate by associating it with the help menu
	static char kDelegateKey;
	objc_setAssociatedObject(helpMenu, &kDelegateKey, delegate, OBJC_ASSOCIATION_RETAIN);
}


#pragma mark -
#pragma mark items
// ----------------------------------------------------------------------------------------------------
// items
// ----------------------------------------------------------------------------------------------------

- (void)addItem:(NSMenuItem *)item {
	[items addObject:item];
}

- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)idx {
	[items insertObject:newItem atIndex:idx];
}

- (NSArray *)itemArray {
	return items;
}


#pragma mark -
#pragma mark menu delegate
// ----------------------------------------------------------------------------------------------------
// menu delegate
// ----------------------------------------------------------------------------------------------------
// any delegate methods implemented here will have the return values be ignored. this is because this
// controller isn't a real delegate, it's actually just being notified of delegate methods that are
// being called.
// ----------------------------------------------------------------------------------------------------

- (void)menuWillOpen:(NSMenu *)menu {
	openMenu = menu;
	if (!eventTap) {
		eventTap = CGEventTapCreate(kCGHIDEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly,
									CGEventMaskBit(kCGEventFlagsChanged), flagsChanged, NULL);
		runLoopSource = CFMachPortCreateRunLoopSource(NULL, eventTap, 0);
		if (!eventTap || !runLoopSource) {
			if (eventTap) { CFRelease(eventTap); eventTap = NULL; }
			if (runLoopSource) { CFRelease(runLoopSource); runLoopSource = NULL; }
			FRLog(@"Failed to setup event tap for extra help menu");
		}
	}
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
}

- (void)menuDidClose:(NSMenu *)menu {
	if (eventTap) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
		CFRelease(eventTap); eventTap = NULL;
		CFRelease(runLoopSource); runLoopSource = NULL;
	}
	openMenu = nil;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
	BOOL hidden = !(GetCurrentKeyModifiers() & optionKey);
	NSArray *all = [[NSArray arrayWithObject:separator] arrayByAddingObjectsFromArray:items];
	for (NSMenuItem *item in all) {
		if ([menu indexOfItem:item] == -1) {
			[menu addItem:item];
		}
		[item setHidden:hidden];
	}
}

#pragma mark -
#pragma mark events
// ----------------------------------------------------------------------------------------------------
// events
// ----------------------------------------------------------------------------------------------------

- (void)_modifierFlagsChanged {
	[self menuNeedsUpdate:openMenu];
}

@end


#pragma mark -
#pragma mark notifying delegate
// ----------------------------------------------------------------------------------------------------
// notifying delegate
// ----------------------------------------------------------------------------------------------------

@implementation FRHelpMenuNotifyingDelegate

+ (id)delegateWithOriginal:(id)delegate {
	if ([[delegate class] isSubclassOfClass:[FRHelpMenuNotifyingDelegate class]]) {
		delegate = ((FRHelpMenuNotifyingDelegate *)delegate)->delegate;
	}
	FRHelpMenuNotifyingDelegate *object = [[self alloc] autorelease];
	object->delegate = delegate;
	return object;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	BOOL responds = [delegate respondsToSelector:aSelector];
	if (!responds) {
		responds = [[FRExtraHelpController defaultController] respondsToSelector:aSelector];
	}
	return responds;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	NSMethodSignature *signature = [delegate methodSignatureForSelector:selector];
	if (!signature) {
		signature = [[FRExtraHelpController defaultController] methodSignatureForSelector:selector];
	}
	return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	SEL selector = [invocation selector];
	
	if ([[FRExtraHelpController defaultController] respondsToSelector:selector]) {
		// duplicate invocation to avoid accidentally returning a value from the extra help controller
		NSMethodSignature *signature = [invocation methodSignature];
		NSInvocation *duplicate = [NSInvocation invocationWithMethodSignature:signature];
		[duplicate setSelector:selector];
		void *arg = malloc([signature frameLength]);
		for (NSUInteger i = 0; i < [signature numberOfArguments]; i++) {
			[invocation getArgument:arg atIndex:i];
			[duplicate setArgument:arg atIndex:i];
		}
		free(arg);
		[duplicate setTarget:[FRExtraHelpController defaultController]];
		[duplicate invoke];
	}
	
	// finish with delegate to ensure returned
	// result is that from the delegate
	if ([delegate respondsToSelector:selector]) {
		[invocation setTarget:delegate];
		[invocation invoke];
	}
}


@end

#endif
