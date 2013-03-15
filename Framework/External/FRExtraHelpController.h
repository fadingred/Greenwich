// 
// Copyright (c) 2013 FadingRed LLC
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

/*!
 \brief		Extra help menu
 \details	This should be used as the help menu delegate. It will show items
			only when the option key is pressed.
 */
@interface FRExtraHelpController : NSObject {
	NSMenu *openMenu;
	NSMenuItem *separator;
	NSMutableArray *items;
	CFMachPortRef eventTap;
	CFRunLoopSourceRef runLoopSource;
}

+ (id)defaultController;

/*!
 \brief		Installs the extra help items
 \details	Sets up the extra help controller to work with the last
			item in the main menu (which it assumes is the help menu).
 */
- (void)install;

/*!
 \brief		Add an item
 \details	Add an extra help item
 */
- (void)addItem:(NSMenuItem *)item;

/*!
 \brief		Insert an item
 \details	Insert an extra help item
 */
- (void)insertItem:(NSMenuItem *)newItem atIndex:(NSInteger)index;

/*!
 \brief		Get the item array
 \details	All of the extra help items
 */
- (NSArray *)itemArray;

@end
