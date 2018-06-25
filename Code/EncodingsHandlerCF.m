//
// EncodingsHandlerCF.m
// Copyright 2008-2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import "EncodingsHandlerCF.h"

@implementation EncodingsHandlerCF

/*
 Return the list of encodings to check.
*/
- (NSArray *) createEncodingsList {
	const NSArray * unwantedList = @[
		@(kCFStringEncodingUnicode),
		@(kCFStringEncodingUTF8),
		@(kCFStringEncodingNonLossyASCII),
		@(kCFStringEncodingUTF16),
		@(kCFStringEncodingUTF16BE),
		@(kCFStringEncodingUTF16LE),
		@(kCFStringEncodingUTF32),
		@(kCFStringEncodingUTF32BE),
		@(kCFStringEncodingUTF32LE),
	];
	
	// Leave out EBCDIC encodings by default, they seem more distracting than relevant.
	NSNumber * includeEBCDICPreference = [[NSUserDefaults standardUserDefaults] valueForKey:includeEBCDICDefaultsKey];
	if (!includeEBCDICPreference || !includeEBCDICPreference.boolValue) {
		unwantedList = [unwantedList arrayByAddingObjectsFromArray:@[
			@(kCFStringEncodingEBCDIC_CP037),
			@(kCFStringEncodingEBCDIC_US)
		]];
	}
	
	// 146 encodings are known by docs, function returns around 101, though (X.5.3)
	NSMutableArray * list = [[NSMutableArray alloc] initWithCapacity:146];
	const CFStringEncoding * encList = CFStringGetListOfAvailableEncodings();
	for (; *encList != kCFStringEncodingInvalidId; encList++) {
		NSNumber * encodingNumber = @(* encList);
		if (![unwantedList containsObject:encodingNumber]) {
			[(NSMutableArray *)list addObject:encodingNumber];
		}
	}
	
	return [list copy];
}



/*
 Return whether the string s can be converted to the string encoding encoding.
*/
- (BOOL) canConvertString:(NSString *)s toEncoding:(NSNumber *)encodingNumber {
	CFStringRef CFs = (__bridge CFStringRef)s;
	CFStringEncoding encoding = encodingNumber.unsignedIntValue;
	CFRange range = CFRangeMake(0, CFStringGetLength(CFs));
	CFIndex numChars = CFStringGetBytes(CFs, range, encoding, 0, NO, nil, 0, nil);
	
	return (numChars == range.length);
}



/*
 Convert the string s to the string encoding with the given encodingNumber.
*/
- (NSString *) convert:(NSString *)input forEncoding:(NSNumber *)encodingNumber {
	NSString * result = nil;
	
	if (input.length > 0 && encodingNumber != nil) {
		NSMutableData * stringData = [NSMutableData dataWithCapacity:[input length]];
		CFRange rangeToProcess = CFRangeMake(0, CFStringGetLength((CFStringRef)input));
		
		while (rangeToProcess.length > 0) {
			UInt8 localBuffer[100];
			CFIndex usedBufferLength;
			CFIndex numChars = CFStringGetBytes((CFStringRef)input, rangeToProcess, encodingNumber.unsignedIntValue, 0, FALSE, (UInt8 *)localBuffer, 100, &usedBufferLength);
			[stringData appendBytes:(UInt8 *)localBuffer length:usedBufferLength];
			
			if (numChars == 0 || numChars != rangeToProcess.length) {
				// We failed to convert anything.
				break;
			}
			
			// Update the remaining range to continue looping
			rangeToProcess.location += numChars;
			rangeToProcess.length -= numChars;
		}
		
		result = (NSString *) CFBridgingRelease(CFStringCreateWithBytes(NULL, stringData.bytes, stringData.length, kCFStringEncodingUTF8, false));
	}
	
	return result;
}



/*
 Return the name of the encoding with the number passed.
*/
- (NSString *) encodingNameForNumber:(NSNumber *)encodingNumber {
	return (NSString *)CFStringGetNameOfEncoding(encodingNumber.unsignedIntValue);
}

@end
