//
// UTF8UnshredderController.h
// Copyright 2008-2014 Sven-S. Porst, earthlingsoft, http://earthlingsoft.net/ssp
// Some rights reserved: http://opensource.org/licenses/mit
// https://github.com/earthlingsoft/UnicodeChecker-UTF8Unshredder
//

#import <Cocoa/Cocoa.h>
#import <UCUtility/UCUtility.h>

@class EncodingsHandler;


@interface UTF8UnshredderController : NSObject <UCUtility>

extern NSString * const useCarbonEncodingsDefaultsKey;
extern NSString * const preferredEncodingDefaultsKey;

extern NSString * const conversionResult;
extern NSString * const conversionEncoding;

@property (strong) IBOutlet NSView * view;
@property (strong) IBOutlet NSPopUpButton * popup;

@property (strong) EncodingsHandler * encodingsHandler;

@property (strong) NSString * inputString;

@property (strong) NSString * resultString;
@property (strong) NSString * resultMessage;
@property (strong) NSString * resultTooltip;
@property (strong) NSNumber * needEncodingsPopup;
@property (strong) NSNumber * foundEncodings;
@property (strong) NSNumber * selectedEncoding;


- (IBAction) changedPopupSelection:(id)sender;

@end
