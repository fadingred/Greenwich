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

#if defined(REDFOUNDATION_LEOPARD_BASE) // not supported
#else

@interface NSFileManager (FRFileManagerArchivingAdditions)

/*!
 \brief		Compress a file or directory
 \details	Create a tar/bzip2 compressed version of the source at the destination.
 */
- (BOOL)compressItemAtPath:(NSString *)sourcePath
						to:(NSString *)destinationPath
					 error:(NSError **)error;

/*!
 \brief		Compress a files and/or directories
 \details	Create a tar/bzip2 compressed version of the sources at the destination.
 */
- (BOOL)compressItems:(NSArray *)relativePaths relativeToDirectory:(NSString *)directory
				   to:(NSString *)destinationPath
				error:(NSError **)error;

/*!
 \brief		Uncompress a file or directory
 \details	Create a tar/bzip2 compressed version of the source at the destination.
 */

- (BOOL)uncompressItemAtPath:(NSString *)sourcePath
						  to:(NSString *)destinationPath
					   error:(NSError **)error;

@end

#endif
