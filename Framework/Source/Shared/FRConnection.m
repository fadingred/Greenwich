// 
// Copyright (c) 2013 FadingRed LLC
// Copyright (c) 2009 Peter Bakhyryev <peter@byteclub.com>, ByteClub LLC
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

#import "FRConnection.h"

void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info);
void writeStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info);

@interface FRConnection ()
@property (copy, nonatomic) NSString *host;
@property (assign, nonatomic) uint16_t port;
@property (assign, nonatomic) int socket;

- (void)handleReadStreamEvent:(CFStreamEventType)event;
- (void)handleWriteStreamEvent:(CFStreamEventType)event;
- (void)readFromStream;
- (void)writeToStream;
@end


@implementation FRConnection
@synthesize delegate;
@synthesize host;
@synthesize port;
@synthesize socket;

- (id)init {
	if ((self = [super init])) {
		socket = -1;
		port = -1;
		host = nil;
		readBuffer = [[NSMutableData alloc] init];
		writeBuffer = [[NSMutableData alloc] init];
	}
	return self;
}

- (id)initWithSocketHandle:(int)socketHandle {
	if ((self = [self init])) {
		socket = socketHandle;
	}
	return self;
}

- (id)initWithHost:(NSString *)aHost port:(uint16_t)aPort {
	if ((self = [self init])) {
		host = [aHost copy];
		port = aPort;
	}
	return self;
}

- (void)dealloc {
	[self close];
}

- (BOOL)connect {
	if (readStream && writeStream) { return FALSE; }
	
	BOOL success = TRUE;
	
	// create read and write streams
	if (self.socket != -1) {
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, self.socket, &readStream, &writeStream);
	}
	else if (self.host && self.port != -1) {
		CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)self.host, self.port,
										   &readStream, &writeStream);
	}
	else { success = FALSE; }
	
	if (!readStream || !writeStream) {
		success = FALSE;
	}
	
	if (success) {
		// the socket should be closed if either of the steams are closed
		CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		
		CFOptionFlags events =
			kCFStreamEventOpenCompleted | kCFStreamEventHasBytesAvailable | kCFStreamEventCanAcceptBytes |
			kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;
		CFStreamClientContext context = {0, (__bridge void *)self, NULL, NULL, NULL};

		// set callback functions
		CFReadStreamSetClient(readStream, events, readStreamEventHandler, &context);
		CFWriteStreamSetClient(writeStream, events, writeStreamEventHandler, &context);
		
		// schedule with runloop
		CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	}
	
	if (success) {
		// open the streams
		if (!CFReadStreamOpen(readStream) || !CFWriteStreamOpen(writeStream)) {
			success = FALSE;
		}
	}
	
	if (!success) {
		[self close];
	}

	return success;
}

- (void)close {
	if (readStream) {
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFReadStreamClose(readStream);
		CFRelease(readStream);
		readStream = NULL;
	}
	if (writeStream) {
		CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFWriteStreamClose(writeStream);
		CFRelease(writeStream);
		writeStream = NULL;
	}
	[readBuffer setData:[NSData data]];
	[writeBuffer setData:[NSData data]];
	readOpen = FALSE;
	writeOpen = FALSE;
	host = nil;
	port = -1;
	socket = -1;
}

- (void)sendMessage:(NSDictionary *)message {
	NSData *rawPacket = [NSKeyedArchiver archivedDataWithRootObject:message];
	int32_t packetLength = htonl([rawPacket length]);
	[writeBuffer appendBytes:&packetLength length:sizeof(int32_t)];
	[writeBuffer appendData:rawPacket];
	[self writeToStream];
}

- (void)handleReadStreamEvent:(CFStreamEventType)event {
	if (event == kCFStreamEventOpenCompleted) { readOpen = YES; }
	else if (event == kCFStreamEventHasBytesAvailable) { [self readFromStream]; }
	else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred) {
		if (readOpen && writeOpen) {
			[self.delegate connectionTerminated:self];
		}
		else {
			[self.delegate connectionFailed:self];
		}
		[self close];
	}
}

- (void)readFromStream {
	BOOL success = TRUE;
	
	while(CFReadStreamHasBytesAvailable(readStream)) {
		NSUInteger bufferSize = 1024;
		NSUInteger currentLength = [readBuffer length];
		[readBuffer increaseLengthBy:bufferSize];
		char *buffer = ((char *)[readBuffer mutableBytes]) + currentLength;
		
		CFIndex len = CFReadStreamRead(readStream, (UInt8 *)buffer, bufferSize);
		if (len <= 0) {
			[self close];
			[delegate connectionTerminated:self];
			success = FALSE;
			break;
		}
		else { [readBuffer setLength:currentLength + len]; }
	}
	
	BOOL messagesToExtract = TRUE;
	while (success && messagesToExtract) {
		const char *buffer = [readBuffer bytes];
		NSUInteger bufferLength = [readBuffer length];
		NSUInteger headerSize = sizeof(int32_t);
		if (bufferLength >= headerSize) {
			int32_t messageSize = 0;
			memcpy(&messageSize, buffer, headerSize);
			messageSize = ntohl(messageSize);
			buffer += headerSize;
			bufferLength -= headerSize;
			if (bufferLength >= (NSUInteger)messageSize) {
				NSData *rawMessage = [NSData dataWithBytes:buffer length:bufferLength];
				NSDictionary *message = [NSKeyedUnarchiver unarchiveObjectWithData:rawMessage];
				[readBuffer replaceBytesInRange:NSMakeRange(0, headerSize+messageSize) withBytes:NULL length:0];
				[self.delegate connection:self receivedMessage:message];
			}
			else { messagesToExtract = FALSE; }
		}
		else { messagesToExtract = FALSE; }
	}
}

- (void)handleWriteStreamEvent:(CFStreamEventType)event {
	if (event == kCFStreamEventOpenCompleted) { writeOpen = YES; }
	else if (event == kCFStreamEventCanAcceptBytes) { [self writeToStream]; }
	else if (event == kCFStreamEventEndEncountered || event == kCFStreamEventErrorOccurred) {
		if (readOpen && writeOpen) {
			[self.delegate connectionTerminated:self];
		}
		else {
			[self.delegate connectionFailed:self];
		}
		[self close];
	}
}

- (void)writeToStream {
	if (!writeOpen || ![writeBuffer length]) { return; }
	if (!CFWriteStreamCanAcceptBytes(writeStream) ) { return; }
	
	CFIndex writtenBytes = CFWriteStreamWrite(writeStream, [writeBuffer bytes], [writeBuffer length]);
	if (writtenBytes == -1) {
		[self close];
		[self.delegate connectionTerminated:self];
	}
	else {
		[writeBuffer replaceBytesInRange:NSMakeRange(0, writtenBytes) withBytes:NULL length:0];
	}
}

void readStreamEventHandler(CFReadStreamRef stream, CFStreamEventType eventType, void *info) {
	[(__bridge FRConnection *)info handleReadStreamEvent:eventType];
}

void writeStreamEventHandler(CFWriteStreamRef stream, CFStreamEventType eventType, void *info) {
	[(__bridge FRConnection *)info handleWriteStreamEvent:eventType];
}

@end
