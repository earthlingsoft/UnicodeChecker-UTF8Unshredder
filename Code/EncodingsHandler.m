//
// EncodingsHandler.m
// Copyright 2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import "EncodingsHandler.h"

@implementation EncodingsHandler

NSString * const includeEBCDICDefaultsKey = @"UTF-8 Unshredder uses EBCDIC Encodings";



- (instancetype) init {
	self = [super init];
	if (self != nil) {
		self.encodings = [self createEncodingsList];
	}
	return self;
}



/*
 Return the list of encodings to check.
 Implemented in subclasses.
*/
- (NSArray *) createEncodingsList {
	return @[];
}



/*
 Return whether the string s can be converted to the string encoding encoding.
 Implemented in subclasses.
*/
- (BOOL) canConvertString:(NSString *)s toEncoding:(NSNumber *)encodingNumber {
	return NO;
}



/*
 Convert the string s to the string encoding with the given encodingNumber.
 Implemented in subclasses.
*/
- (NSString *) convert:(NSString *)input forEncoding:(NSNumber *)encodingNumber {
	return @"";
}



/*
 Return the name of the encoding with the number passed.
 Implemented in subclasses.
*/
- (NSString *) encodingNameForNumber:(NSNumber *)encodingNumber {
	return @"";
}



/*
 Return the names of the encodings with the numbers passed.
*/
- (NSArray *) encodingNamesForNumbers:(NSArray *)encodingNumbers {
	NSMutableArray * encodingNames = [NSMutableArray arrayWithCapacity:encodingNumbers.count];
	[encodingNumbers enumerateObjectsUsingBlock:^(id encodingNumber, NSUInteger idx, BOOL *stop) {
		[encodingNames addObject:[self encodingNameForNumber:encodingNumber]];
	}];
	return [encodingNames copy];
}

@end
