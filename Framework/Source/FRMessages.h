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

#define safe __unsafe_unretained

/*!
 \brief		Resources message
 \details	Sent from the iOS server back to the Mac app and includes information on all localizable
			strings files.
 */
extern const struct FRLocalizationResourcesMessage {
	safe NSString *messageID;
	struct {
		safe NSString *applicationIdentifier;
		safe NSString *applicationName;
		safe NSString *resources;
		struct {
			safe NSString *bundleIdentifier;
			safe NSString *language;
			safe NSString *name;
			safe NSString *data;
		} resource;
	} keys;
} FRLocalizationResourcesMessage;

/*!
 \brief		Changes message
 \details	Sent from the Mac client app back to the iOS server indicating the localizations
			that the user has performed.
 */
extern const struct FRLocalizationChangesMessage {
	safe NSString *messageID;
	struct {
		safe NSString *resources;
		struct {
			safe NSString *bundleIdentifier;
			safe NSString *language;
			safe NSString *name;
			safe NSString *data;
		} resource;
	} keys;
} FRLocalizationChangesMessage;

#undef safe
