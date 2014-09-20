//
// EncodingsHandler.h
// Copyright 2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import <Foundation/Foundation.h>

@interface EncodingsHandler : NSObject

extern NSString * const includeEBCDICDefaultsKey;

@property (strong) NSArray * encodings;

- (NSArray *) createEncodingsList;
- (NSString *) encodingNameForNumber:(NSNumber *)number;
- (NSArray *) encodingNamesForNumbers:(NSArray *)encodingNumbers;

- (BOOL) canConvertString:(NSString *)s toEncoding:(NSNumber *)encodingNumber;
- (NSString *) convert:(NSString *)input forEncoding:(NSNumber *)encoding;

@end
