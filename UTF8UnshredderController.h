//
//  UTF8UnshredderController.h
//  UC UTF8 Unshredder
//
//  Created by  Sven on 08.05.08.
//  Copyright 2008 earthlingsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UCUtility/UCUtility.h>

#define USECARBONPREFSKEY @"UTF-8 Unshredder uses Carbon Text encodings"
#define INCLUDEEBCDICPREFSKEY @"UTF-8 Unshredder uses EBCDIC Encodings"
#define PREFERREDENCODINGPREFSKEY @"UTF-8 Unshredder preferred Encoding"

#define CONVERSIONRESULT @"conversionResult"
#define CONVERSIONENCODING @"encoding"

@interface UTF8UnshredderController : NSObject <UCUtility> {
	NSString * inputString;
	NSString * resultString;
	NSString * resultMessage;
	NSString * resultTooltip;
	NSNumber * needEncodingsPopup;
	NSNumber * foundEncodings;
	
	NSNumber * preferredEncoding;
	NSNumber * selectedEncoding;
	
	NSArray * encodingList;
	
	IBOutlet NSView *view;
	IBOutlet NSView *initialKeyView;	
	IBOutlet NSPopUpButton * popup;
	
	
	BOOL useCarbonEncodings;
}

- (IBAction) changedPopupSelection: (id) sender;

- (void) rebuildPopupWithEncodings: (NSArray*) encodingsArray;

- (NSArray*) buildEncodingList;
- (BOOL) canConvertString: (NSString*) s toEncoding:(NSNumber*) encodingNumber;
- (NSString *) convert:(NSString *) input forEncoding:(NSNumber*) encoding;
- (NSString *) encodingNameForNumber: (NSNumber*) number;
@end
