//
//  KTDocument+Properties.m
//  Marvel
//
//  Created by Terrence Talbot on 4/6/05.
//  Copyright 2005 Biophony LLC. All rights reserved.
//

#import "KTDocument.h"

#import "Debug.h"

#import "KTTransferController.h"
#import "KTDocWindowController.h"
#import "KTDocSiteOutlineController.h"
#import "KTDocumentInfo.h"
#import "KTHTMLInspectorController.h"
#import "KTStalenessManager.h"

#import "NSIndexSet+Karelia.h"

#import <iMediaBrowser/RBSplitView.h>


@interface KTDocument (PropertiesPrivate)
- (void)updateDefaultDocumentProperty:(NSString *)key;
@end


@implementation KTDocument ( Properties )

#pragma mark -
#pragma mark Properties that do not inherit from the preferences

- (NSIndexSet *)lastSelectedRows
{
	// we are storing NSIndexSets internally as strings
	NSString *string = [self wrappedValueForKey:@"lastSelectedRows"];
	return [NSIndexSet indexSetWithString:string];			// warning: accessors that convert from object cannot be for optional properties
}

- (void)setLastSelectedRows:(NSIndexSet *)value
{
	// we store NSIndexSets internally as a string
	NSString *string = [value indexSetAsString];
	[self setWrappedValue:string forKey:@"lastSelectedRows"];
}

- (NSSet *)requiredBundlesIdentifiers
{
	return [[self documentInfo] requiredBundlesIdentifiers];
}

- (void)setRequiredBundlesIdentifiers:(NSSet *)identifiers
{
	[[self documentInfo] setRequiredBundlesIdentifiers:identifiers];
}

#pragma mark .... relationships

/*  This method is no longer public, just there for backwards-compatibility. Use -documentInfo instead.
 */
- (KTPage *)root { return [[self documentInfo] root]; }

#pragma mark ivar accessors (not stored objects)

- (NSTimer *)autosaveTimer
{
	return myAutosaveTimer;
}

- (void)setAutosaveTimer:(NSTimer *)aTimer
{
	if ( nil == aTimer ) LOG((@"stopping autosave timer"));
	
	[aTimer retain];
	if ( [myAutosaveTimer isValid] )
	{
		[myAutosaveTimer invalidate];
	}
	[myAutosaveTimer release];
	myAutosaveTimer = aTimer;
}

- (BOOL)connectionsAreConnected
{
	if ( [[myExportTransferController connection] isConnected]
		 || [[myLocalTransferController connection] isConnected]
		 || [[myRemoteTransferController connection] isConnected] )
	{
		return YES;
	} 
	else
	{
		return NO;
	}
}

#pragma mark -
#pragma mark Staleness

- (KTStalenessManager *)stalenessManager
{
	/*if (!myStalenessManager)
	{
		myStalenessManager = [[KTStalenessManager alloc] initWithDocument:self];
	}*/
	
	return myStalenessManager;
}

#pragma mark -
#pragma mark Other

- (KTDocumentInfo *)documentInfo
{
    return myDocumentInfo;
}

- (void)setDocumentInfo:(KTDocumentInfo *)aDocumentInfo
{
    [aDocumentInfo retain];
    [myDocumentInfo release];
    myDocumentInfo = aDocumentInfo;
}

#pragma mark -
#pragma mark Publishing

- (KTTransferController *)exportTransferController
{
    return myExportTransferController; 
}

- (void)setExportTransferController:(KTTransferController *)anExportTransferController
{
	if ( nil != myExportTransferController )
	{
		[self removeWindowController:myExportTransferController];
	}
	
    [anExportTransferController retain];
    [myExportTransferController release];
    myExportTransferController = anExportTransferController;
	
	if ( nil != myExportTransferController )
	{
		[self addWindowController:myExportTransferController];
	}
}

- (BOOL)isReadOnly
{
	BOOL result = NO; // default is that we assume we are writable
	
	NSString *documentPath = [[self fileURL] path];
	if ( nil != documentPath )
	{
		BOOL isWithinAppWrapper = [documentPath hasPrefix:[[NSBundle mainBundle] bundlePath]];
		BOOL isWritableAtPath = [[NSFileManager defaultManager] isWritableFileAtPath:documentPath];
		
		if ( isWithinAppWrapper || !isWritableAtPath )
		{
			result = YES;
		}
	}
	
	return result;
}

- (NSDate *)lastSavedTime { return myLastSavedTime; }

- (void)setLastSavedTime:(NSDate *)aLastSavedTime
{
    [aLastSavedTime retain];
    [myLastSavedTime release];
    myLastSavedTime = aLastSavedTime;
}

- (KTTransferController *)localTransferController
{
    return myLocalTransferController;
}

- (void)setLocalTransferController:(KTTransferController *)aLocalTransferController
{
	if ( nil != myLocalTransferController )
	{
		[self removeWindowController:myLocalTransferController];
	}
	
    [aLocalTransferController retain];
    [myLocalTransferController release];
    myLocalTransferController = aLocalTransferController;
	
	if ( nil != myLocalTransferController )
	{
		[self addWindowController:myLocalTransferController];
	}
}

//- (KTOldMediaManager *)oldMediaManager
//{
//    return myOldMediaManager;
//}
//
//- (void)setOldMediaManager:(KTOldMediaManager *)aMediaManager
//{
//    [aMediaManager retain];
//    [myOldMediaManager release];
//    myOldMediaManager = aMediaManager;
//}

//- (NSMutableArray *)peerContexts
//{
//	return myPeerContexts;
//}

//- (void)setPeerContexts:(NSMutableArray *)aMutableArray
//{
//	@synchronized ( myPeerContexts )
//	{
//		[aMutableArray retain];
//		[myPeerContexts release];
//		myPeerContexts = aMutableArray;
//	}
//}

- (KTTransferController *)remoteTransferController
{
    return myRemoteTransferController;
}

- (void)setRemoteTransferController:(KTTransferController *)aRemoteTransferController
{
	if ( nil != myRemoteTransferController )
	{
		[self removeWindowController:myRemoteTransferController];
	}
	
    [aRemoteTransferController retain];
    [myRemoteTransferController release];
    myRemoteTransferController = aRemoteTransferController;
	
	if ( nil != myRemoteTransferController )
	{
		[self addWindowController:myRemoteTransferController];
	}
}

- (BOOL)showDesigns
{
	return myShowDesigns;
}

- (void)setShowDesigns:(BOOL)value
{
	myShowDesigns = value;
}

- (void)terminateConnections
{
	[myExportTransferController terminateConnection];
	[myLocalTransferController terminateConnection];
	[myRemoteTransferController terminateConnection];
}

- (void)setHTMLInspectorController:(KTHTMLInspectorController *)anHTMLInspectorController
{
    [anHTMLInspectorController retain];
    [myHTMLInspectorController release];
    myHTMLInspectorController = anHTMLInspectorController;
}

- (KTHTMLInspectorController *)HTMLInspectorControllerWithoutLoading	// lazily instantiate
{
	return myHTMLInspectorController;
}

- (KTHTMLInspectorController *)HTMLInspectorController	// lazily instantiate
{
	if ( nil == myHTMLInspectorController )
	{
		KTHTMLInspectorController *controller = [[[KTHTMLInspectorController alloc] init] autorelease];
		[self setHTMLInspectorController:controller];
		[self addWindowController:controller];
	}
	return myHTMLInspectorController;
}

//- (BOOL)suspendSavesDuringPeerCreation
//{
//	return mySuspendSavesDuringPeerCreation;
//}
//
//- (void)setSuspendSavesDuringPeerCreation:(BOOL)aFlag
//{
//	mySuspendSavesDuringPeerCreation = aFlag;
//}

#pragma mark -
#pragma mark Document Display Properties

// these were changed from setWrapped to setPrimitive to avoid being marked on undo stack

- (BOOL)displaySiteOutline { return myDisplaySiteOutline; }

- (void)setDisplaySiteOutline:(BOOL)value
{
	myDisplaySiteOutline = value;
	[self updateDefaultDocumentProperty:@"displaySiteOutline"];
}

- (BOOL)displayStatusBar { return myDisplayStatusBar; }

- (void)setDisplayStatusBar:(BOOL)value
{
	myDisplayStatusBar = value;
	[self updateDefaultDocumentProperty:@"displayStatusBar"];
}

- (BOOL)displayEditingControls { return myDisplayEditingControls; }

- (void)setDisplayEditingControls:(BOOL)value
{
	myDisplayEditingControls = value;
	[self updateDefaultDocumentProperty:@"displayEditingControls"];
}

- (BOOL)displaySmallPageIcons { return myDisplaySmallPageIcons; }

- (void)setDisplaySmallPageIcons:(BOOL)aSmall
{
	myDisplaySmallPageIcons = aSmall;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"KTDisplaySmallPageIconsDidChange"
														object:self];
														
	[[self windowController] updatePopupButtonSizesSmall:aSmall];
	[self updateDefaultDocumentProperty:@"displaySmallPageIcons"];
}

- (float)textSizeMultiplier { return myTextSizeMultiplier; }

- (void)setTextSizeMultiplier:(float)value { myTextSizeMultiplier = value; }

- (BOOL)displayCodeInjectionWarnings { return myDisplayCodeInjectionWarnings; }

- (void)setDisplayCodeInjectionWarnings:(BOOL)flag
{
	myDisplayCodeInjectionWarnings = flag;
	[self updateDefaultDocumentProperty:@"displayCodeInjectionWarnings"];
}

- (NSRect)documentWindowContentRect
{
	NSString *rectAsString = [self wrappedValueForKey:@"documentWindowContentRect"];
	if ( nil != rectAsString )
	{
		return NSRectFromString(rectAsString);
	}
	else
	{
		return NSZeroRect;
	}
}

#pragma mark support

/*	Support method for whenever the user changes a view property of the document.
 *	We write a copy of the last used properties out to the defaults so that new documents can use them.
 */
- (void)updateDefaultDocumentProperty:(NSString *)key
{
	NSDictionary *existingProperties =
		[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultDocumentProperties"];
	
	NSMutableDictionary *updatedProperties;
	if (existingProperties)
	{
		updatedProperties = [NSMutableDictionary dictionaryWithDictionary:existingProperties];
		[updatedProperties setObject:[self valueForKey:key] forKey:key];
	}
	else
	{
		updatedProperties = [NSDictionary dictionaryWithObject:[self valueForKey:key] forKey:key];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:updatedProperties forKey:@"defaultDocumentProperties"];
}

/*	Generally this method is used when saving the document.
 *	We don't want manage these view properties in the model normally since they would be affected by undo/redo.
 *	Instead, they are kept within KTDocument and then only written out at save-time.
 */
- (void)copyDocumentDisplayPropertiesToModel
{
	// Selected pages
	NSIndexSet *outlineSelectedRowIndexSet = [[[[self windowController] siteOutlineController] siteOutline] selectedRowIndexes];
	NSIndexSet *storedIndexSet = [self lastSelectedRows];
	
	if ( ![storedIndexSet isEqualToIndexSet:outlineSelectedRowIndexSet] )
	{
		[self setLastSelectedRows:outlineSelectedRowIndexSet];	
	}
	
	
	// Source Outline width
	float width = [[[[self windowController] siteOutlineSplitView] subviewAtPosition:0] dimension];
	[[self documentInfo] setInteger:width forKey:@"sourceOutlineSize"];
	
	
	// Icon size
	[[self documentInfo] setBool:[self displaySmallPageIcons] forKey:@"displaySmallPageIcons"];
	
	
	// Window size
	BOOL saveContentRect = NO;
	NSRect currentContentRect = NSZeroRect;
	NSRect storedContentRect = [self documentWindowContentRect];
	NSWindow *window = [[self windowController] window];
	if ( nil != window )
	{
		NSRect frame = [window frame];
		currentContentRect = [window contentRectForFrameRect:frame];
		if ( !NSEqualRects(currentContentRect, NSZeroRect) )
		{
			if ( !NSEqualRects(currentContentRect, storedContentRect) )
			{
				saveContentRect = YES;
			}
		}
	}
	
	if (saveContentRect)	// store content rect, if needed
	{
		[[self documentInfo] setValue:NSStringFromRect(currentContentRect) forKey:@"documentWindowContentRect"];
	}
}

#pragma mark -
#pragma mark *valueForKey: support

- (id)wrappedValueForKey:(NSString *)aKey
{
	OFF((@"WARNING: wrappedValueForKey: %@ is being called on a document; it MUST BE REPLACED with a call to DocumentInfo directly to make KVO happy", aKey));
	KTDocumentInfo *documentInfo = [self documentInfo];
	
//	[documentInfo lockPSCAndMOC];
    [documentInfo willAccessValueForKey:aKey];
	id result = [documentInfo primitiveValueForKey:aKey];
	[documentInfo didAccessValueForKey:aKey];
//	[documentInfo unlockPSCAndMOC];

    return result;
}

//#warning setWrappedValue:forKey: SHOULD NOT BE USED TO SET A RELATIONSHIP (IT WILL DIE DOWNSTREAM)
//#warning setWrappedValue:forKey: ALSO WILL NOT SET BOTH SIDES OF A RELATIONSHIP
- (void)setWrappedValue:(id)aValue forKey:(NSString *)aKey
{
	OFF((@"WARNING: setWrappedValue:forKey: %@ is being called on a document; it MUST BE REPLACED with a call to DocumentInfo directly to make KVO happy", aKey));
	KTDocumentInfo *documentInfo = [self documentInfo];

//	[documentInfo lockPSCAndMOC];
    [documentInfo willChangeValueForKey:aKey];
    [documentInfo setPrimitiveValue:aValue forKey:aKey];
    [documentInfo didChangeValueForKey:aKey];
//	[documentInfo unlockPSCAndMOC];
}

- (id)wrappedInheritedValueForKey:(NSString *)aKey
{
	OFF((@"WARNING: wrappedInheritedValueForKey: %@ is being called on KTDocument -- is this a property stored in defaults?", aKey));
    id result = [[self documentInfo] valueForKey:aKey];
	if ( nil == result )
	{
		result = [[NSUserDefaults standardUserDefaults] objectForKey:aKey];
		if ( nil != result )
		{
			// for now, we're going to specialize support for known entities
			// in the model that we want to be inheritied.
			KTDocumentInfo *documentInfo = [self documentInfo];
//				[documentInfo lockPSCAndMOC];
			[documentInfo setPrimitiveValue:result forKey:aKey];
//				[self refreshObjectInAllOtherContexts:(KTManagedObject *)documentInfo];
//				[documentInfo unlockPSCAndMOC];
		}
	}
	return result;
}

- (void)setWrappedInheritedValue:(id)aValue forKey:(NSString *)aKey
{
	OFF((@"WARNING: setWrappedInheritedValue:forKey: %@ is being called on KTDocument -- is this a property stored in defaults?", aKey));

	[self setWrappedValue:aValue forKey:aKey];
	
	// we only want to be storing property values in defaults
	// for now, we're going to specialize support for known entities
	// in the model that we want to be inheritied.
	id value = aValue;
	if ( [aKey isEqualToString:@"hostProperties"] )
	{
		value = [value dictionary]; // convert KTStoredSet to NSDictionary
	}
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:aKey];
}

- (void)setPrimitiveInheritedValue:(id)aValue forKey:(NSString *)aKey
{
	LOG((@"WARNING: setPrimitiveInheritedValue:forKey: %@ is being called on KTDocument -- is this a property stored in defaults?", aKey));

	KTDocumentInfo *documentInfo = [self documentInfo];

//	[documentInfo lockPSCAndMOC];
    [documentInfo setPrimitiveValue:aValue forKey:aKey];
//	[documentInfo unlockPSCAndMOC];
    [[NSUserDefaults standardUserDefaults] setObject:aValue forKey:aKey];
}

@end
