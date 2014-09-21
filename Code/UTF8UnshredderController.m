//
// UTF8UnshredderController.m
// Copyright 2008-2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import "UTF8UnshredderController.h"
#import "EncodingsHandlerCF.h"
#import "EncodingsHandlerNS.h"


@implementation UTF8UnshredderController

NSString * const useCarbonEncodingsDefaultsKey = @"UTF-8 Unshredder uses Carbon Text encodings";
NSString * const preferredEncodingDefaultsKey = @"UTF-8 Unshredder preferred Encoding";

NSString * const conversionResult = @"conversionResult";
NSString * const conversionEncoding = @"encoding";



- (instancetype) init {
	self = [super init];
	
	if (self != nil) {
		BOOL useCarbonEncodings = YES;
		NSNumber * carbonEncodingsPrefsValue = [[NSUserDefaults standardUserDefaults] objectForKey:useCarbonEncodingsDefaultsKey];
		if (carbonEncodingsPrefsValue) {
			useCarbonEncodings = carbonEncodingsPrefsValue.boolValue;
		}
		if (useCarbonEncodings) {
			self.encodingsHandler = [[EncodingsHandlerCF alloc] init];
		}
		else {
			self.encodingsHandler = [[EncodingsHandlerNS alloc] init];
		}
		
		[self addObserver:self forKeyPath:@"inputString" options:(NSKeyValueObservingOptionNew) context:nil];
		[self addObserver:self forKeyPath:@"selectedEncoding" options:(NSKeyValueObservingOptionNew) context:nil];
	}

	return self;
}



- (void) awakeFromNib {
	// to let us have inactive items in the popup
	[self.popup setAutoenablesItems:NO];
}



- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"inputString"]) {
		// new input string => process it
		[self processString:self.inputString];
	}
	else if ([keyPath isEqualToString:@"selectedEncoding"]) {
		// selected encoding has changed => update output
		self.resultString = [self.encodingsHandler convert:self.inputString forEncoding:self.selectedEncoding];
	}
}



- (void) processString:(NSString *)s {
	// 1. Determine possible encodings
	NSDictionary * conversionResults = [self conversionResultsForString:s];
	
	// Only use conversion results if we have working encodings and the input is not ASCII
	self.foundEncodings = @((conversionResults.count != 0) && (![s canBeConvertedToEncoding:NSASCIIStringEncoding]));
	
	// 2. Determine the encoding to select by default
	NSNumber * encoding = nil;
	if (self.foundEncodings.boolValue) {
		// Determine which encoding to select
		NSNumber * preferredEncoding = [[NSUserDefaults standardUserDefaults] objectForKey:preferredEncodingDefaultsKey];
		if (preferredEncoding && conversionResults[preferredEncoding]) {
			// 2a. Use the preferred encoding if available
			encoding = preferredEncoding;
		}
		else if (conversionResults[self.selectedEncoding]) {
			// 2b. … otherwise use the currently selected encoding if available
			encoding = self.selectedEncoding;
		}
		else {
			// 2c. … otherwise use the first encoding in the list
			encoding = conversionResults.allKeys[0];
		}
	}
	
	// Rebuild the popup menu and select item in it (bindings don’t seem to work here)
	[self rebuildPopupWithEncodings:conversionResults];
	[self.popup selectItemAtIndex:[self.popup.menu indexOfItemWithRepresentedObject:self.selectedEncoding]];
	
	// 3. Present result
	NSString * message = @"";
	NSString * tooltip = @"";
	BOOL needPopupMenu = NO;
	
	if (self.foundEncodings.boolValue) {
		// The string could be shredded UTF-8
		if (conversionResults.count == 1)  {
			// There is a single working encoding
			message = [NSString stringWithFormat:@"The input may have been UTF-8 that has been interpreted in the \342\200\234%@\342\200\235 encoding.", [self.encodingsHandler encodingNameForNumber:conversionResults.allKeys[0]], nil];
		}
		else {
			// There are several working encodings
			NSSet * distinctResults = [NSSet setWithArray:conversionResults.allValues];
			BOOL encodingsDiffer = (distinctResults.count > 1);
			
			if (encodingsDiffer) {
				// the encodings give different results -> we need the popup menu
				needPopupMenu = YES;
				message = @"The input may have been UTF-8 that has been interpreted as:";
			}
			else {
				// the different encodings all give the same result
				message = [NSString stringWithFormat:@"The input may have been UTF-8. Interpreting it in %lu encodings gives the string below.", (unsigned long)conversionResults.count, nil];
				
				NSArray * encodingNames = [self.encodingsHandler encodingNamesForNumbers:conversionResults.allKeys];
				NSString * encodingNamesString = [encodingNames componentsJoinedByString:@",\n"];
				tooltip = [NSString stringWithFormat:@"The encodings in question are:\n%@.", encodingNamesString];
			}
		}
	}
	else {
		// !success - the string could not have been shredded
		if (s.length == 0) {
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
			
			NSArray * encodingNames = [self.encodingsHandler encodingNamesForNumbers:self.encodingsHandler.encodings];
			NSString * encodingNamesString = [encodingNames componentsJoinedByString:@", "];
			tooltip = [NSString stringWithFormat:@"The known encodings are: %@.", encodingNamesString];
		}
	}
	
	self.selectedEncoding = encoding;
	self.resultMessage = message;
	self.resultTooltip = tooltip;
	self.needEncodingsPopup = @(needPopupMenu);
}



/*
 For the given string return a dictionary with:
	* keys: feasible encodings
	* values: encoding results
*/
- (NSDictionary *) conversionResultsForString:(NSString *)s {
	NSMutableDictionary * conversionResults = [NSMutableDictionary dictionary];
	
	for (NSNumber * encodingNumber in self.encodingsHandler.encodings) {
		if ([self.encodingsHandler canConvertString:s toEncoding:encodingNumber]) {
			// conversion of the string could be done in theory
			NSString * convertedString = [self.encodingsHandler convert:s forEncoding:encodingNumber];
			if (convertedString != nil) {
				// ... and yields a valid UTF-8 string
				if (![convertedString isEqualToString:s]) {
					// ... which actually differs from the original
					conversionResults[encodingNumber] = convertedString;
				}
			}
		}
	}
	
	return [conversionResults copy];
}




- (void) rebuildPopupWithEncodings:(NSDictionary *)conversionResults {
	NSArray * sortedKeys = [conversionResults keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSComparisonResult result = [conversionResults[obj1] compare:conversionResults[obj2]];
		if (result == NSOrderedSame) {
			result = [obj1 compare:obj2];
		}
		return result;
	}];
	
	[self.popup removeAllItems];
	
	__block NSString * previousResult = nil;
	[sortedKeys enumerateObjectsUsingBlock:^(NSNumber * encodingNumber, NSUInteger idx, BOOL *stop) {
		NSString * encodingResult = conversionResults[encodingNumber];
		if (![previousResult isEqualToString:encodingResult]) {
			// the result changes between the previous item and the new one -> insert a separator into the menu
			if (previousResult) {
				// no separator before the first item
				[self.popup.menu addItem:[NSMenuItem separatorItem]];
			}
			NSMenuItem * stringItem = [[NSMenuItem alloc] initWithTitle:encodingResult action:NULL keyEquivalent:@""];
			stringItem.enabled = NO;
			[self.popup.menu addItem:stringItem];
		}
		[self.popup addItemWithTitle:[self.encodingsHandler encodingNameForNumber:encodingNumber]];
		[self.popup.lastItem setRepresentedObject:encodingNumber];
		previousResult = encodingResult;
	}];
}






/*
	When the popup’s selection was changed manually, store the selected value as preferredEncoding.
	The preferred encoding will be be given precendence when having to select an encoding
	The IBAction is called after KVO, so we just have to copy selectedEncoding over to preferredEncoding.
*/
- (IBAction) changedPopupSelection:(id)sender {
	[[NSUserDefaults standardUserDefaults] setValue:self.selectedEncoding forKey:preferredEncodingDefaultsKey];
}



/*
	Delegate method for the text field.
	We don’t want text to be editable, but we cannot mark the text field non-editable as that would take it out of the tab loop.
*/
- (BOOL) control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	return NO;
}





#pragma mark UCUtility protocol

- (void) newInput:(id)sender {
	self.inputString = [sender stringValue];
}

- (NSString *) identifier {
    return @"UTF8Unshredder";
}

- (NSString *) toolbarLabel {
    return @"UTF-8 Unshredder";
}

- (NSString *) toolbarToolTip {
    return @"Fix UTF-8 strings that have been garbled by wrong use of text encodings.";
}

- (NSImage *) toolbarImage {
    NSBundle * myBundle = [NSBundle bundleForClass:[self class]];
    NSString * imagePath = [myBundle pathForResource:@"Icon" ofType:@"png"];
    return [[NSImage alloc] initByReferencingFile:imagePath];
}

- (NSView *) utilityView {
	NSArray * nibObjects;
    if(!self.view) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"Unshredder" owner:self topLevelObjects:&nibObjects];
    }
    return self.view;
}

- (NSView *) initialKeyView {
	return self.popup;
}

@end
