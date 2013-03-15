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

#import "FRNetworkClient.h"

@implementation FRNetworkClient
@synthesize delegate;

- (id)init {
	if ((self = [super init])) {
		browser = [[NSNetServiceBrowser alloc] init];
		[browser setDelegate:self];
		[browser searchForServicesOfType:@"_greenwich._tcp" inDomain:@""];
	}
	return self;
}

- (void)resolveServiceAndMakeConnection:(NSNetService *)aService {
	if (!service) {
		service = aService;
		[service setDelegate:self];
		[service resolveWithTimeout:5.0];
	}
}

- (void)startConnectionForService:(NSNetService *)aService {
	if (!connection && (aService == service)) {
		connection = [[FRConnection alloc] initWithHost:[service hostName] port:[service port]];
		connection.delegate = self;
		[connection connect];
		
		if ([self.delegate respondsToSelector:@selector(networkClient:didCreateConnection:)]) {
			[self.delegate networkClient:self didCreateConnection:connection];
		}
	}
}


#pragma mark -
#pragma mark properties
// ----------------------------------------------------------------------------------------------------
// properties
// ----------------------------------------------------------------------------------------------------

- (FRConnection *)activeConnection {
	return connection;
}

#pragma mark -
#pragma mark connection delegate
// ----------------------------------------------------------------------------------------------------
// connection delegate
// ----------------------------------------------------------------------------------------------------

- (void)connectionFailed:(FRConnection *)aConnection {
	if ([self.delegate respondsToSelector:@selector(networkClient:didCloseConnection:)]) {
		[self.delegate networkClient:self didCloseConnection:aConnection];
	}
	connection = nil;
	service = nil;
}

- (void)connectionTerminated:(FRConnection *)aConnection {
	if ([self.delegate respondsToSelector:@selector(networkClient:didCloseConnection:)]) {
		[self.delegate networkClient:self didCloseConnection:aConnection];
	}
	connection = nil;
	service = nil;
}

- (void)connection:(FRConnection *)aConnection receivedMessage:(NSDictionary *)message {
	if ([self.delegate respondsToSelector:@selector(networkClient:receivedMessage:fromConnection:)]) {
		[self.delegate networkClient:self receivedMessage:message fromConnection:aConnection];
	}
}


#pragma mark -
#pragma mark net services browser delegate
// ----------------------------------------------------------------------------------------------------
// net services browser delegate
// ----------------------------------------------------------------------------------------------------

- (void)handleError:(NSNumber *)error withBrowser:(NSNetServiceBrowser *)theBrowser {
    FRLog(@"An error occurred with service browser, error code = %@", error);
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)theBrowser {}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)theBrowser {}

- (void)netServiceBrowser:(NSNetServiceBrowser *)theBrowser
			 didNotSearch:(NSDictionary *)errorDict {
	[self handleError:[errorDict objectForKey:NSNetServicesErrorCode] withBrowser:theBrowser];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)theBrowser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
	[self resolveServiceAndMakeConnection:aNetService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)theBrowser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
	if (aNetService == service) { service = nil; }
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

- (void)netServiceDidResolveAddress:(NSNetService *)netService {
	[self startConnectionForService:netService];
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict {
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode] withService:netService];
}

@end
