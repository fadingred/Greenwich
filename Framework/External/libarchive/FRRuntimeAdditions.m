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

#ifndef REDLINKED_RUNTIME_ADDITIONS

#import <objc/runtime.h>

#import "FRRuntimeAdditions.h"

BOOL class_swizzleMethodAndStore(Class class, SEL original, IMP replacement, IMPPointer store);
BOOL class_swizzleMethodAndStore(Class class, SEL original, IMP replacement, IMPPointer store) {
	BOOL success = FALSE;
	IMP imp = NULL;
	Method method = class_getInstanceMethod(class, original);
	if (method) {
		// ensure the method is defined in this class by trying to add it to the class, get the new method
		// pointer if it was actually added (this is now considered the original), then get the imp for the
		// original method & replace the method.
		const char *type = method_getTypeEncoding(method);
		if (class_addMethod(class, original, method_getImplementation(method), type)) {
			method = class_getInstanceMethod(class, original);
		}
		imp = method_getImplementation(method);
		success = TRUE;
		class_replaceMethod(class, original, replacement, type);
	}
	if (imp && store) { *store = imp; }
	return success;
}

void *object_getClassPointer(__unsafe_unretained id obj) { return (__bridge void *)object_getClass(obj); }
void *objc_getClassPointer(const char *name) { return (__bridge void *)objc_getClass(name); }
void *objc_allocateClassPairPointer(Class superclass, const char *name, size_t extraBytes) {
	return (__bridge void *)objc_allocateClassPair(superclass, name, extraBytes);
}

@implementation NSObject (FRRuntimeAdditions)
+ (BOOL)swizzle:(SEL)original with:(IMP)replacement store:(IMPPointer)store {
	return class_swizzleMethodAndStore(self, original, replacement, store);
}
+ (BOOL)swizzleClassMethod:(SEL)original with:(IMP)replacement store:(IMPPointer)store {
	return class_swizzleMethodAndStore(object_getClass(self), original, replacement, store);
}
@end

#endif
