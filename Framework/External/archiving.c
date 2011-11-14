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
#elif defined(REDLINKED_ARCHIVING) // not needed, linked in
#else

#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <dirent.h>
#include <archive.h>
#include <archive_entry.h>

#import "archiving.h"

static int append_path_recursively(const char *pathname, struct archive *a, struct archive *disk);

int archive_create_tar_bzip2(const char **pathnames) {
	int error = 0;
	
	struct archive *disk = archive_read_disk_new();
	archive_read_disk_set_standard_lookup(disk);

	struct archive *a = archive_write_new();
	archive_write_set_compression_bzip2(a);
	archive_write_set_format_ustar(a);
	archive_write_open_file(a, NULL);
	
	while (*pathnames) {
		append_path_recursively(*pathnames, a, disk);
		pathnames++;
	}
	
	archive_write_close(a);
	archive_write_finish(a);
	
	return error;
}

static int append_path_recursively(const char *pathname, struct archive *a, struct archive *disk) {
	int error = 0;
	
	struct archive_entry *entry = archive_entry_new();
	archive_entry_set_pathname(entry, pathname);
	struct stat st;
	stat(pathname, &st);
	archive_read_disk_entry_from_file(disk, entry, -1, &st);
	archive_write_header(a, entry);
	int fd = open(pathname, O_RDONLY);
	ssize_t amt = 0;
	static char buffer[16*1024];
	while ((amt = read(fd, buffer, sizeof(buffer))) > 0) {
		archive_write_data(a, buffer, amt);
	}
	close(fd);
	archive_entry_free(entry);
	
	if (S_ISLNK(st.st_mode)) { } // don't recurse into symbolic link dirs
	else if (S_ISDIR(st.st_mode)) {
		DIR *dir = opendir(pathname);
		struct dirent *dirent = NULL;
		while ((dirent = readdir(dir))) {
			if (strcmp(dirent->d_name, ".") == 0 ||
				strcmp(dirent->d_name, "..") == 0) { continue; }
			
			char *subpath = NULL;
			asprintf(&subpath, "%s/%s", pathname, dirent->d_name);
			error = append_path_recursively(subpath, a, disk);
			free(subpath);
			
			if (error != 0) { break; }
		}
	}
	
	return error;
}

int archive_extract_tar_bzip2(void) {
	struct archive *a;
	struct archive *ext;
	int r = 0;
	int flags = 0;
	int error = 0;
	
	a = archive_read_new();
	archive_read_support_format_tar(a);
	archive_read_support_compression_bzip2(a);
	
	ext = archive_write_disk_new();
	archive_write_disk_set_options(ext, flags);

	if ((r = archive_read_open_file(a, NULL, 10240))) {
		fprintf(stderr, "archiving: %s", archive_error_string(a));
		error = r;
	}
	else {
		for (;;) {
			struct archive_entry *entry;
			r = archive_read_next_header(a, &entry);
			if (r == ARCHIVE_EOF) { break; }
			if (r != ARCHIVE_OK) {
				fprintf(stderr, "archiving: %s", archive_error_string(a));
				error = 1;
				break;
			}
			if (archive_write_header(ext, entry) != ARCHIVE_OK) {
				fprintf(stderr, "archiving: %s", archive_error_string(ext));
			}
			else {
				const void *buff;
				size_t size;
				off_t offset;
				
				for (;;) {
					r = archive_read_data_block(a, &buff, &size, &offset);
					if (r == ARCHIVE_EOF) { r = ARCHIVE_OK; break; }
					if (r != ARCHIVE_OK) {
						fprintf(stderr, "archiving: %s", archive_error_string(ext));
						break;
					}
					r = archive_write_data_block(ext, buff, size, offset);
					if (r != ARCHIVE_OK) {
						fprintf(stderr, "archiving: %s", archive_error_string(ext));
						break;
					}
				}
				if (r != ARCHIVE_OK) {
					error = 1;
					break;
				}
				
				r = archive_write_finish_entry(ext);
				if (r != ARCHIVE_OK) {
					fprintf(stderr, "archiving: %s", archive_error_string(ext));
					error = 1;
					break;
				}
			}
		}
	}
	archive_read_close(a);
	archive_read_finish(a);
	
	return error;
}

#endif
