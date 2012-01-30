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

#import <netinet/in.h>
#import <sys/socket.h>

#import "FRNetworkServer__.h"

static void callback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface FRNetworkServer ()
- (BOOL)setupServer;
@end

@implementation FRNetworkServer
@synthesize delegate;

- (id)init {
	if ((self = [super init])) {
		[self performSelector:@selector(setupServer) withObject:nil afterDelay:0];
	}
	return self;
}

- (BOOL)setupServer {
	BOOL success = TRUE;
	uint16_t port = 0;
	CFSocketRef socket = NULL;

	// create socket object
	if (success) {
		CFSocketContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
		socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack,
								(CFSocketCallBack)&callback, &context);
		if (!socket) { success = FALSE; }
	}

	// setup listening socket
	if (success) {
		setsockopt(CFSocketGetNative(socket), SOL_SOCKET, SO_REUSEADDR, (void *)&(int){0}, sizeof(int));
		
		struct sockaddr_in address = {
			.sin_len = sizeof(struct sockaddr_in),
			.sin_family = AF_INET,
			.sin_port = 0,
			.sin_addr.s_addr = htonl(INADDR_ANY),
		};
		
		NSData *data = [NSData dataWithBytes:&address length:sizeof(address)];
		if (CFSocketSetAddress(socket, (__bridge CFDataRef)data) != kCFSocketSuccess) {
			success = FALSE;
		}
	}
	
	// get assigned port
	if (success) {
		NSData *data =  (__bridge_transfer NSData *)CFSocketCopyAddress(socket);
		struct sockaddr_in address;
		memcpy(&address, [data bytes], [data length]);
		port = ntohs(address.sin_port);
	}
	
	// schedule with run loop
	if (success) {
		CFRunLoopRef currentRunLoop = CFRunLoopGetCurrent();
		CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0);
		CFRunLoopAddSource(currentRunLoop, runLoopSource, kCFRunLoopCommonModes);
		CFRelease(runLoopSource);
	}

	// setup service
	if (success) {
		service = [[NSNetService alloc] initWithDomain:@"" type:@"_greenwich._tcp" name:@"Greenwich" port:port];
		if (!service) { success = FALSE; }
	}
	
	// publish service
	if (success) {
		[service setDelegate:self];
		[service publish];

	}
	
	// cleanup
	if (socket != NULL) {
		CFRelease(socket);
		socket = NULL;
	}

	return success;
}

static void callback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	if (type != kCFSocketAcceptCallBack) { return; }
	
	FRNetworkServer *server = (__bridge FRNetworkServer *)info;
	int sock = *(CFSocketNativeHandle *)data;
	
	if (!server->connection) {
		server->connection = nil;
		server->connection = [[FRConnection alloc] initWithSocketHandle:sock];
		server->connection.delegate = server;
		
		if (server->connection) { [server->connection connect]; }
		else { close(sock); }
		
		[server.delegate networkServer:server receivedMessage:nil fromConnection:server->connection];
	}
	else { close(sock); }
}

#pragma mark -
#pragma mark connection delegate
// ----------------------------------------------------------------------------------------------------
// connection delegate
// ----------------------------------------------------------------------------------------------------

- (void)connectionFailed:(FRConnection *)aConnection {
	connection = nil;
}

- (void)connectionTerminated:(FRConnection *)aConnection {
	connection = nil;
}

- (void)connection:(FRConnection *)aConnection receivedMessage:(NSDictionary *)message {
	[self.delegate networkServer:self
				 receivedMessage:message
				  fromConnection:aConnection];;
}

#pragma mark -
#pragma mark net services delegate
// ----------------------------------------------------------------------------------------------------
// net services delegate
// ----------------------------------------------------------------------------------------------------

- (void)handleError:(NSNumber *)error withService:(NSNetService *)theService {
    FRLog(@"An error occurred with service %@.%@.%@, error code = %@",
		  [theService name],
		  [theService type],
		  [theService domain],
		  error);
}

@end
