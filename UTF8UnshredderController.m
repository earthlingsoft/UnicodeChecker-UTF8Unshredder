//
//  UTF8UnshredderController.m
//  UC UTF8 Unshredder
//
//  Created by  Sven on 08.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import "UTF8UnshredderController.h"


@implementation UTF8UnshredderController

- (id) init {
	self = [super init];
	
	useCarbonEncodings = YES;
	NSNumber * carbonEncodingsPrefsValue = [[NSUserDefaults  standardUserDefaults] objectForKey:USECARBONPREFSKEY];
	if (carbonEncodingsPrefsValue) {
		[self setValue:carbonEncodingsPrefsValue forKey:@"useCarbonEncodings"];
	}
	
	NSNumber * preferredEncodingPrefsValue = [[NSUserDefaults  standardUserDefaults] objectForKey:PREFERREDENCODINGPREFSKEY];
	if (preferredEncodingPrefsValue) {
		[self setValue:preferredEncodingPrefsValue forKey:@"preferredEncoding"];
	}
	
	
	[self setValue:[self buildEncodingList] forKey:@"encodingList"];	
	
	[self addObserver:self forKeyPath:@"inputString" options:(NSKeyValueObservingOptionNew) context:nil];
	[self addObserver:self forKeyPath:@"selectedEncoding" options:(NSKeyValueObservingOptionNew) context:nil];

	return self;
}



- (void) awakeFromNib {
	// to let us have inactive items in the popup
	[popup setAutoenablesItems:NO];
}



/*
- (void) dealloc {
	[super dealloc];
}
*/




- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"inputString"]) {
		// string has changed

		// 1. determine possible encodings
		
		// build array of encodings that are possible:
		NSString * s = [self valueForKey:@"inputString"];
		NSMutableArray * encodingsArray = [NSMutableArray array];
		NSMutableArray * encodingsArray2 = [NSMutableArray array];
		NSNumber * encodingNumber;
		NSEnumerator * myEnum = [encodingList objectEnumerator];
		while (encodingNumber = [myEnum nextObject]) {
			if ([self canConvertString:s toEncoding:encodingNumber]) {
				// conversion of the string could be done in theory
				NSString * convertedString = [self convert:s forEncoding:encodingNumber];
				if (convertedString != nil) {
					// ... and yields a valid UTF-8 string
					if (![convertedString isEqualToString:s]) {
						// ... which actually differs from the original
						[encodingsArray2 addObject:[NSDictionary dictionaryWithObjectsAndKeys:
												   encodingNumber, CONVERSIONENCODING,
												   convertedString, CONVERSIONRESULT,
												   nil]];
						[encodingsArray addObject:encodingNumber];
					}
				}
			}
		}
		[self rebuildPopupWithEncodings:encodingsArray2];		
		
		
		// dump results if we don't have any encodings or if the input is ASCII (to avoid confusing results with Mac OS Symbol encoding)
		BOOL success = (([encodingsArray count] != 0) && (![s canBeConvertedToEncoding:NSASCIIStringEncoding]));
		[self setValue:[NSNumber numberWithBool:success] forKey:@"foundEncodings"];
		
		
		// 2. set output string
		NSString * result = nil;
		if (success) {
			// 2a. determine selected encoding
			NSNumber * myEncoding;
			if ([encodingsArray containsObject:preferredEncoding]) {
				// 2a2. otherwise use the preferred Encoding if possible
				myEncoding = preferredEncoding;
			}
			else if ([encodingsArray containsObject:selectedEncoding]) {
				// 2a1. If the currently selecting encoding remains available use that
				myEncoding = selectedEncoding;
			}
			else {
				// 2a3. otherwise use the first encoding in the list *fingers crossed*
				myEncoding = [encodingsArray objectAtIndex:0];
			}
			[self setValue:myEncoding forKey:@"selectedEncoding"];
			result = [self convert: s forEncoding:[self valueForKey:@"selectedEncoding"]];
		}
		else {
			// 2b. Just copy the input string if there was no conversion.
			result = s;
		}
		
		// manually select the item in the rebuilt menu (bindings don't seem to work here)
		[popup selectItemAtIndex:[[popup menu] indexOfItemWithRepresentedObject:[self valueForKey:@"selectedEncoding"]]];
		
		// 3. Present result
		NSString * message = @"";
		NSString * tooltip = @"";
		BOOL needPopup = NO;
		if (success) {
			// The string could be shredded UTF-8
			if ([encodingsArray count] == 1)  {
				// There's a single working encoding
				message = [NSString stringWithFormat:@"The input may have been UTF-8 that has been interpreted in the \342\200\234%@\342\200\235 encoding.", [self encodingNameForNumber:[encodingsArray objectAtIndex:0]], nil];
			}
			else {
				// There are several working encodings
				NSEnumerator * encodingEnumerator = [encodingsArray objectEnumerator];
				NSNumber * encodingNumber;
				NSString * firstString = [self convert:s forEncoding:[encodingEnumerator nextObject]];
				BOOL encodingsDiffer = NO;
				while (encodingNumber = [encodingEnumerator nextObject]) {
					encodingsDiffer = encodingsDiffer || !([firstString isEqualToString:[self convert:s forEncoding:encodingNumber]]);
				}
				if (encodingsDiffer) {
					// the enodings give different results -> we need the popup menu
					needPopup = YES;
					message = @"The input may have been UTF-8 that has been interpreted as:";
				}
				else {
					// the different encodings all give the same result
					message = [NSString stringWithFormat:@"The input may have been UTF-8. Interpreting it in %i encodings gives the string below.", [encodingsArray count], nil];
					encodingEnumerator = [encodingsArray objectEnumerator];
					NSMutableString * encodingNames = [NSMutableString stringWithString:@"The encodings in question are:"];
					while (encodingNumber = [encodingEnumerator nextObject]) {
						[encodingNames appendFormat:@"\n%@,", [self encodingNameForNumber:encodingNumber], nil];
					}
					[encodingNames replaceCharactersInRange:NSMakeRange([encodingNames length] - 1, 1) withString:@"."];
					tooltip = encodingNames;
				}
			}
		}
		else {
			// !success - the string could not have been shredded
			if ([s length] == 0) {
				// the empty string, print some help
				message = @"No input.";
			//	result  = @"If you see a string like \303\203\302\266 where you expected an ö, UTF-8 may have been misinterpreted as an old-fashioned encoding. This utility tries to rectify that problem.";
			}
			else if ([s canBeConvertedToEncoding:NSASCIIStringEncoding]) {
				// the string was actually ASCII, so be helpful and say that.
				message = @"The input is pure ASCII. Nothing to see here.";
				tooltip = @"You may want to enter more text or use a different utility.";
			}
			else {
				// the string could not be made sense of
				message = @"The input did not result from misinterpretation of UTF-8 as one of the known encodings.";
				NSMutableString * encodingNameList = [NSMutableString stringWithString:@"The known encodings are: "];			
				NSEnumerator * encodingEnumerator = [encodingList objectEnumerator];
				NSNumber * encodingNumber;
				while (encodingNumber = [encodingEnumerator nextObject]) {
					[encodingNameList appendFormat:@" %@,", [self encodingNameForNumber:encodingNumber], nil];
				}				
				[encodingNameList replaceCharactersInRange:NSMakeRange([encodingNameList length] - 1, 1) withString:@"."];				
				tooltip = encodingNameList;
			}
		}
		
		[self setValue:result forKey:@"resultString"];			
		[self setValue:message forKey:@"resultMessage"];
		[self setValue:tooltip forKey:@"resultTooltip"];
		[self setValue:[NSNumber numberWithBool:needPopup] forKey:@"needEncodingsPopup"];
	}
	else if ([keyPath isEqualToString:@"selectedEncoding"]) {
		// selected encoding has changed => update output
		NSString * result = [self convert:[self valueForKey:@"inputString"] forEncoding:[self valueForKey:@"selectedEncoding"]];
		[self setValue:result forKey:@"resultString"];			
	}
}




- (void) rebuildPopupWithEncodings: (NSArray*) encodingsArray {
	NSMutableArray * encodings = [encodingsArray mutableCopy];
	NSSortDescriptor * sortByResult =  [[[NSSortDescriptor alloc] initWithKey:CONVERSIONRESULT ascending:YES] autorelease];
	NSSortDescriptor * sortByEncodingNumber =  [[[NSSortDescriptor alloc] initWithKey:CONVERSIONENCODING ascending:YES] autorelease];
	// sort encodings by their results 
	[encodings sortUsingDescriptors:[NSArray arrayWithObjects: sortByResult, sortByEncodingNumber, nil]];
	
	[popup removeAllItems];
	
	NSEnumerator * myEnum = [encodings objectEnumerator];
	NSDictionary * encoding;
	NSString * previousResult = nil;
	while (encoding = [myEnum nextObject]) {
		NSNumber * encodingNumber = [encoding objectForKey:CONVERSIONENCODING];
		NSString * encodingResult = [encoding objectForKey:CONVERSIONRESULT];
		if (![previousResult isEqualToString:encodingResult]) {
			// the result changes between the previous item and the new one -> insert a separator into the menu
			if (previousResult) {
				// no separator before the first item
				[[popup menu] addItem: [NSMenuItem separatorItem]];
			}
			NSMenuItem * representingString = [[[NSMenuItem  alloc] initWithTitle:encodingResult action:NULL keyEquivalent:@""] autorelease];
			[representingString setEnabled:NO];
			[[popup menu] addItem:representingString];
		}
		[popup addItemWithTitle:[self encodingNameForNumber:encodingNumber]];
		[[popup lastItem] setRepresentedObject:encodingNumber];
		previousResult = encodingResult;
	}
}






/* When the popup's selection was changed manually, store the selected value as preferredEncoding.
	The preferred encoding will be be given precendence when having to select an encoding
	The IBAction is called after KVO, so we just have to copy selectedEncoding over to preferredEncoding.
*/
- (IBAction) changedPopupSelection: (id) sender {
	NSNumber * encodingNumber = [self valueForKey:@"selectedEncoding"];
	[self setValue:encodingNumber forKey:@"preferredEncoding"];
	[[NSUserDefaults standardUserDefaults] setValue:encodingNumber forKey:PREFERREDENCODINGPREFSKEY];
}



/* Delegate method for the text field.
	We don't want text to be editable, but we cannot mark the text field non-editable as that would take it out of the tab loop.
*/
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	return NO;
}





#pragma mark ENCODINGS

/*
	Build a list of all encodings we are going to check.
	The useCarbonEncodings variable determines whether this is done NS or CF style.
	In the NS case we use a select list of encodings. In the CF case we use all encodings given to us (sloppy)
*/
- (NSArray*) buildEncodingList {
	NSArray * list;
	if (!useCarbonEncodings) {
		list = [NSArray arrayWithObjects:
				[NSNumber numberWithUnsignedLong:NSISOLatin1StringEncoding],
				[NSNumber numberWithUnsignedLong:NSISOLatin2StringEncoding],
				[NSNumber numberWithUnsignedLong:NSMacOSRomanStringEncoding],
				[NSNumber numberWithUnsignedLong:NSWindowsCP1252StringEncoding],
				[NSNumber numberWithUnsignedLong:NSWindowsCP1251StringEncoding],
				[NSNumber numberWithUnsignedLong:NSWindowsCP1253StringEncoding],
				[NSNumber numberWithUnsignedLong:NSWindowsCP1254StringEncoding],
				[NSNumber numberWithUnsignedLong:NSWindowsCP1250StringEncoding],
				[NSNumber numberWithUnsignedLong:NSNEXTSTEPStringEncoding],
				[NSNumber numberWithUnsignedLong:NSSymbolStringEncoding],
				nil];	
	}
	else {
		NSArray * unwantedList = [NSArray arrayWithObjects:
										 // no Unicode encodings
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUnicode],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF8],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingNonLossyASCII],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF16],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF16BE],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF16LE],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF32],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF32BE],
									[NSNumber numberWithUnsignedLong:kCFStringEncodingUTF32LE],
										 //
								  nil];

		// Kick out EBCDIC encodings by default, they seem more distracting than relevant.
		NSNumber * includeEBCDICPreference = [[NSUserDefaults standardUserDefaults] valueForKey:INCLUDEEBCDICPREFSKEY];
		if (!includeEBCDICPreference || ![includeEBCDICPreference boolValue]) {
			unwantedList = [unwantedList arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:
							[NSNumber numberWithUnsignedLong:kCFStringEncodingEBCDIC_CP037],
							[NSNumber numberWithUnsignedLong:kCFStringEncodingEBCDIC_US],
																		nil]];
		}
		
		// 146 encodings are known by docs, function returns around 101, though (X.5.3)		
		list = [[NSMutableArray alloc] initWithCapacity:146]; 
		const CFStringEncoding *encList = CFStringGetListOfAvailableEncodings();
		for (; *encList != kCFStringEncodingInvalidId; encList++) {
			NSNumber * encodingNumber = [NSNumber numberWithUnsignedLong:*encList];
			if (![unwantedList containsObject:encodingNumber]) {
				[(NSMutableArray*) list addObject:encodingNumber];
			}
		}
	}
	
	return list;
}



/* 
	Returns whether the string s can be converted to the string encoding encoding.
	The useCarbonEncodings variable specifies whether this is done NS or CF style.
*/
- (BOOL) canConvertString: (NSString*) s toEncoding:(NSNumber*) encodingNumber {
	// NSStringEncoding and CFStringEncoding are unsigned long
	unsigned long encoding = [encodingNumber unsignedLongValue]; 	
	BOOL result;
	
	if (!useCarbonEncodings) {
		result = [s canBeConvertedToEncoding:(NSStringEncoding) encoding];
	}
	else {
		CFRange range = CFRangeMake(0, CFStringGetLength((CFStringRef)s));
		CFIndex numChars = CFStringGetBytes((CFStringRef) s, range, (CFStringEncoding) encoding, 0, NO, nil,  0, nil);
		result = (numChars == range.length);
	}
	return result;
}



/*
 Converts the string s to the string encoding whose number is given in the encodingNumber object
 The useCarbonEncodings variable specifies whether this is to be done Carbon or Cocoa style.
*/
- (NSString *) convert:(NSString *) input forEncoding:(NSNumber*) encodingNumber {
	NSString * result = @"";
	// NSStringEncoding and CFStringEncoding are unsigned long
	unsigned long encoding = [encodingNumber unsignedLongValue];
	
	if ([input length] > 0) {
		if (!useCarbonEncodings) {
			const char * chars;
			chars = [input cStringUsingEncoding:(NSStringEncoding) encoding];
			result = [[[NSString alloc] initWithBytes:chars length:strlen(chars) encoding:NSUTF8StringEncoding] autorelease];
		}
		else {
			NSMutableData * theData = [NSMutableData dataWithCapacity:[input length]];
			CFRange rangeToProcess = CFRangeMake(0, CFStringGetLength((CFStringRef)input));
			
			while (rangeToProcess.length > 0) {
				UInt8 localBuffer[100];
				CFIndex usedBufferLength;
				CFIndex numChars = CFStringGetBytes((CFStringRef)input, rangeToProcess, encoding, 0, FALSE, (UInt8 *)localBuffer, 100, &usedBufferLength);
				[theData appendBytes:(UInt8 *)localBuffer length:usedBufferLength];
				
				if (numChars == 0 || numChars != rangeToProcess.length) break;	// Means we failed to convert anything...
				
				// Update the remaining range to continue looping
				rangeToProcess.location += numChars;
				rangeToProcess.length -= numChars;
			}
			
			result = (NSString*) CFStringCreateWithBytes(NULL, [theData bytes], [theData length], kCFStringEncodingUTF8, false);
		}
	}

	return result;
}



/*
 Returns the name of the encoding with the number passed in encodingNumber.
 The useCarbonEncodings variable specifies whether this is done NS or CF style.
 */
- (NSString *) encodingNameForNumber: (NSNumber*) encodingNumber {
	NSString * name;
	unsigned long encoding = [encodingNumber unsignedLongValue];
	
	if (!useCarbonEncodings) {
		name = [NSString localizedNameOfStringEncoding:encoding];
	}
	else {
		name = (NSString*) CFStringGetNameOfEncoding(encoding);
	}
	
	return name;
}






#pragma mark UCUtility protocol

- (void)newInput:(id)sender {
	[self setValue:[sender stringValue] forKey:@"inputString"];
}


- (NSString *)identifier {
    return @"UTF8Unshredder";
}

- (NSString *)toolbarLabel {
    return @"UTF-8 Unshredder";
}

- (NSString *)toolbarToolTip {
    return @"Fix UTF-8 strings that have been garbled by wrong use of text encodings.";
}

- (NSImage *)toolbarImage {
    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [myBundle pathForResource:@"Icon" ofType:@"png"];
    return [[[NSImage alloc] initByReferencingFile:imagePath] autorelease];
}

- (NSView *)utilityView {
    if(!view) {
        [NSBundle loadNibNamed:@"Unshredder" owner:self];
    }
    return view;
}

- (NSView *)initialKeyView {
    return initialKeyView;
}



@end
