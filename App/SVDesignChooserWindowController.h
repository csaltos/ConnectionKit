//
//  SVDesignChooserWindowController.h
//  Sandvox
//
//  Created by Terrence Talbot on 8/28/09.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGScopeBarDelegateProtocol.h"

@class KTDesign;
@class SVDesignChooserViewController;
@interface SVDesignChooserWindowController : NSWindowController <MGScopeBarDelegate>
{
	IBOutlet NSArrayController *oDesignsArrayController;
    IBOutlet SVDesignChooserViewController   *oViewController;
    IBOutlet MGScopeBar             *oScopeBar;
	
	NSString *_genre;
	NSString *_color;
	NSString *_width;

	SEL _selectorWhenChosen;
	id	_targetWhenChosen;		// weak to avoid retain cycle
}

@property(nonatomic, retain) KTDesign *design;

@property(assign) SEL selectorWhenChosen;
@property(assign) id  targetWhenChosen;
@property(retain) SVDesignChooserViewController *viewController;
@property(retain) NSArrayController *designsArrayController;
@property (copy) NSString *genre;
@property (copy) NSString *color;
@property (copy) NSString *width;
@property (readonly) NSString *matchString;

- (IBAction)cancelSheet:(id)sender;
- (IBAction)chooseDesign:(id)sender;

- (void)beginSheetModalForWindow:(NSWindow *)window delegate:(id)aTarget didEndSelector:(SEL)aSelector;

@end
