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

#import "FRFileManagerArchivingAdditions.h"
#import "archiving.h"

#if defined(REDFOUNDATION_LEOPARD_BASE) // not supported
#elif defined(REDLINKED_FILE_MANAGER_ARCHIVING_ADDITIONS) // not needed, linked in
#else

@implementation NSFileManager (FRFileManagerArchivingAdditions)

- (BOOL)compressItemAtPath:(NSString *)source
						to:(NSString *)destination
					 error:(NSError **)error {
	return [self compressItems:[NSArray arrayWithObject:[source lastPathComponent]]
		   relativeToDirectory:[source stringByDeletingLastPathComponent]
							to:destination error:error];
}

- (BOOL)compressItems:(NSArray *)relativePathnames relativeToDirectory:(NSString *)directory
				   to:(NSString *)destination error:(NSError **)error {
	
	
	BOOL success = FALSE;
	
	mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
	int flag = O_WRONLY | O_CREAT | O_EXCL;
	int write_fd = open([destination fileSystemRepresentation], flag, mode);
	if (write_fd < 0) {
		if (error) { *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:write_fd userInfo:nil]; }
		success = FALSE;
	}
	else {
		size_t count = [relativePathnames count];
		const char **pathnames = malloc(sizeof(char *) * (count + 1));
		[relativePathnames enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			pathnames[idx] = strdup([obj fileSystemRepresentation]);
		}];
		pathnames[count] = NULL;
		
		// create the compression task
		char *chdir_location = strdup([directory fileSystemRepresentation]);
		
		pid_t pid = fork();
		if (pid < 0) { FRLog(@"Failed to fork"); }
		else if (pid == 0) {
			dup2(write_fd, STDOUT_FILENO);
			close(write_fd);
			chdir(chdir_location);
			_exit(archive_create_tar_bzip2(pathnames));
		}
		else {
			close(write_fd);
		}
		
		int status = 0;
		waitpid(pid, &status, 0);
		
		success = (WIFEXITED(status) == true && WEXITSTATUS(status) == 0);
		if (success) { } // nothing to do on success
		else {
			if (error) { *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:WEXITSTATUS(status) userInfo:nil]; }
		}
		
		// free memory
		for (size_t i = 0; i <= count; i++) { free((char *)pathnames[i]); }
		free(pathnames);
		free(chdir_location);
	}
	
	return success;
}

- (BOOL)uncompressItemAtPath:(NSString *)source
						  to:(NSString *)destination
					   error:(NSError **)error {
	
	BOOL success = FALSE;
	
	int read_fd = open([source fileSystemRepresentation], O_RDONLY);
	if (read_fd < 0) {
		if (error) { *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:read_fd userInfo:nil]; }
		success = FALSE;
	}
	else {
		// get a unique temp directory
		char *dirname = NULL;
		asprintf(&dirname, "%s/XXXXXX", [NSTemporaryDirectory() fileSystemRepresentation]);
		char *chdir_location = mkdtemp(dirname);

		// create the extraction task
		pid_t pid = fork();
		if (pid < 0) { FRLog(@"Failed to fork"); }
		else if (pid == 0) {
			dup2(read_fd, STDIN_FILENO);
			close(read_fd);
			chdir(chdir_location);
			_exit(archive_extract_tar_bzip2());
		}
		else {
			close(read_fd);
		}

		int status = 0;
		waitpid(pid, &status, 0);

		success = (WIFEXITED(status) == true && WEXITSTATUS(status) == 0);
		if (success) {
			NSFileManager *manager = [NSFileManager defaultManager];
			NSString *extractPath = [manager stringWithFileSystemRepresentation:chdir_location
																		 length:strlen(chdir_location)];
			NSArray *extractedItems = [self contentsOfDirectoryAtPath:extractPath error:error];
			if ([extractedItems count] == 1) {
				NSString *extractedItemName = [extractedItems lastObject];
				NSString *extractedItemPath = [extractPath stringByAppendingPathComponent:extractedItemName];
				if (extractedItemPath) {
					success = [self moveItemAtPath:extractedItemPath toPath:destination error:error];
				}
			}
			else {
				success = [self createDirectoryAtPath:destination withIntermediateDirectories:YES
										   attributes:nil error:error];
				if (success) {
					for (NSString *itemName in extractedItems) {
						NSString *moveFrom = [extractPath stringByAppendingPathComponent:itemName];
						NSString *moveTo = [destination stringByAppendingPathComponent:itemName];
						success = [self moveItemAtPath:moveFrom toPath:moveTo error:error];
						if (!success) { break; }
					}
				}
			}
		}
		else {
			if (error) { *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:WEXITSTATUS(status) userInfo:nil]; }
		}
		
		free(chdir_location);
	}
	
	return success;
}

@end

#endif
