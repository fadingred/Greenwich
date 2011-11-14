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

#import <Foundation/Foundation.h>

typedef IMP *IMPPointer;

@interface NSObject (FRRuntimeAdditions)

/*!
 \brief		Performs a method swizzle
 \details	Swizzles original with replacement.
 			This is a little different from traditional method swizzling, but the concept is the same. The
			original method will be replaced by a new method, and you can have the old implementation stored
			in an IMP pointer for use in the swizzled method. This works out to be a little safer than method
			swizzling since the _cmd argument can be passed through to the original IMP unaltered.
 */
+ (BOOL)swizzle:(SEL)original with:(IMP)replacement store:(IMPPointer)store;

/*!
 \brief		Performs a class method swizzle
 \details	Swizzles original with replacement.
 \see		NSObject::swizzle:with:store: for details.
 */
+ (BOOL)swizzleClassMethod:(SEL)original with:(IMP)replacement store:(IMPPointer)store;

@end

/*!
 \brief		Simply calls builtin method
 \details	This shouldn't really be needed. We're waiting for some comipler fixes for this.
 */
void *object_getClassPointer(__unsafe_unretained id object);

/*!
 \brief		Simply calls builtin method
 \details	This shouldn't really be needed. We're waiting for some comipler fixes for this.
 */
void *objc_getClassPointer(const char *name);

/*!
 \brief		Simply calls builtin method
 \details	This shouldn't really be needed. We're waiting for some comipler fixes for this.
 */
void *objc_allocateClassPairPointer(Class superclass, const char *name, size_t extraBytes);
