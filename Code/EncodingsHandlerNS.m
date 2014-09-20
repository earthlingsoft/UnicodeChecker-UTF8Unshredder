//
// EncodingsHandlerNS.m
// Copyright 2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import "EncodingsHandlerNS.h"

@implementation EncodingsHandlerNS

/*
 Return the list of encodings to check.
*/
- (NSArray *) createEncodingsList {
	NSArray * list = @[
		@(NSISOLatin1StringEncoding),
		@(NSISOLatin2StringEncoding),
		@(NSMacOSRomanStringEncoding),
		@(NSWindowsCP1250StringEncoding),
		@(NSWindowsCP1251StringEncoding),
		@(NSWindowsCP1252StringEncoding),
		@(NSWindowsCP1253StringEncoding),
		@(NSWindowsCP1254StringEncoding),
		@(NSNEXTSTEPStringEncoding),
		@(NSJapaneseEUCStringEncoding),
		@(NSShiftJISStringEncoding),
		@(NSISO2022JPStringEncoding),
		@(NSSymbolStringEncoding)
	];

	return list;
}



/*
 Return whether the string s can be converted to the string encoding encoding.
*/
- (BOOL) canConvertString:(NSString *)s toEncoding:(NSNumber *)encodingNumber {
	NSStringEncoding encoding = encodingNumber.unsignedLongValue;
	return [s canBeConvertedToEncoding:encoding];
}



/*
 Convert the string s to the string encoding with the given encodingNumber.
*/
- (NSString *) convert:(NSString *)input forEncoding:(NSNumber *)encodingNumber {
	NSString * result = nil;
	
	if (input.length > 0 && encodingNumber != nil) {
		const char * chars;
		chars = [input cStringUsingEncoding:encodingNumber.unsignedLongValue];
		result = [[NSString alloc] initWithBytes:chars length:strlen(chars) encoding:NSUTF8StringEncoding];
	}
	
	return result;
}



/*
 Return the name of the encoding with the number passed.
*/
- (NSString *) encodingNameForNumber:(NSNumber *)encodingNumber {
	return [NSString localizedNameOfStringEncoding:encodingNumber.unsignedLongValue];
}

@end
