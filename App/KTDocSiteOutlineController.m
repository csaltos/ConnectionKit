//
//  KTDocSiteOutlineController.m
//  Marvel
//
//  Created by Terrence Talbot on 1/2/08.
//  Copyright 2008 Karelia Software. All rights reserved.
//

#import "KTDocSiteOutlineController.h"
#import "KTSiteOutlineDataSource.h"

#import "Debug.h"
#import "KTAbstractElement.h"
#import "KTAppDelegate.h"
#import "KTDataSource.h"
#import "KTDocWebViewController.h"
#import "KTDocWindowController.h"
#import "KTDocument.h"
#import "KTElementPlugin.h"
#import "KTHTMLInspectorController.h"
#import "KTImageTextCell.h"
#import "KTMaster.h"
#import "KTPage.h"
#import "NSAttributedString+Karelia.h"
#import "NSDate+Karelia.h"
#import "NSOutlineView+KTExtensions.h"
#import "NSString+Karelia.h"


/*	These strings are localizations for case https://karelia.fogbugz.com/default.asp?4736
 *	Not sure when we're going to have time to implement it, so strings are placed here to ensure they are localized.
 *
 *	NSLocalizedString(@"There is already a page with the file name \\U201C%@.\\U201D Do you wish to rename it to \\U201C%@?\\U201D",
					  "Alert message when changing the file name or extension of a page to match an existing file");
 *	NSLocalizedString(@"There are already some pages with the same file name as those you are adding. Do you wish to rename them to be different?",
					  "Alert message when pasting/dropping in pages whose filenames conflict");
 */


@interface KTDocWindowController (PrivatePageStuff)
- (void)insertPage:(KTPage *)aPage parent:(KTPage *)aCollection;
@end


#pragma mark -


@interface KTDocSiteOutlineController (Private)
- (void)setSiteOutline:(NSOutlineView *)outlineView;

- (NSSet *)pages;
- (void)addPagesObject:(KTPage *)aPage;
- (void)removePagesObject:(KTPage *)aPage;
@end


#pragma mark -


@implementation KTDocSiteOutlineController

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	if ([key isEqualToString:@"selectedPages"])
	{
		return NO;
	}
	else
	{
		return [super automaticallyNotifiesObserversForKey:key];
	}
}

+ (void)initialize
{
	[self setKey:@"selectedPages" triggersChangeNotificationsForDependentKey:@"selectedPage"];
}

#pragma mark -
#pragma mark Init/Dealloc/Awake

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	
	if ( nil != self )
	{
		mySiteOutlineDataSource = [[KTSiteOutlineDataSource alloc] initWithSiteOutlineController:self];
		
		// Prepare tree controller parameters
		[self setChildrenKeyPath:@"sortedChildren"];
		[self setAvoidsEmptySelection:NO];
		[self setPreservesSelection:NO];
		[self setSelectsInsertedObjects:NO];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pageIconSizeDidChange:)
												 name:@"KTDisplaySmallPageIconsDidChange"
											   object:[[self windowController] document]];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setSiteOutline:nil];
	
	
	// Release remaining iVars
	[mySelectedPages release];
	
	[mySiteOutlineDataSource release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (void)setContent:(id)content
{
	[super setContent:content];
	
	// At the same time, clear out pages list
	[mySiteOutlineDataSource resetPageObservation];
}

- (KTDocWindowController *)windowController { return myWindowController; }

- (void)setWindowController:(KTDocWindowController *)controller
{
	myWindowController = controller;
	
	if (!controller)
	{
		[self setSiteOutline:nil];
	}
	return;
	// Connect tree controller stuff up to the controller/doc
	KTDocument *document = [controller document];
	[self setManagedObjectContext:[document managedObjectContext]];
	[self setContent:[document root]];
}

- (NSOutlineView *)siteOutline { return siteOutline; }

- (void)setSiteOutline:(NSOutlineView *)outlineView
{
	// Dump the old outline
	NSOutlineView *oldSiteOutline = [self siteOutline];
	[oldSiteOutline setDataSource:nil];
	[oldSiteOutline setDelegate:nil];
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter removeObserver:self name:NSOutlineViewSelectionDidChangeNotification object:oldSiteOutline];
	[notificationCenter removeObserver:self name:NSOutlineViewItemWillCollapseNotification object:oldSiteOutline];
	
	// Set up the appearance of the new view
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:@"displayName"];
	KTImageTextCell *imageTextCell = [[[KTImageTextCell alloc] init] autorelease];
	[imageTextCell setEditable:YES];
	[tableColumn setDataCell:imageTextCell];
	
	[outlineView setIntercellSpacing:NSMakeSize(3.0, 1.0)];
	
	
	// Set up the behaviour of the new view
	[outlineView setTarget:myWindowController];
	[outlineView setDoubleAction:@selector(showInfo:)];
	
	NSMutableArray *dragTypes = [NSMutableArray arrayWithArray:[KTDataSource allDragSourceAcceptedDragTypesForPagelets:NO]];
	[dragTypes addObject:kKTOutlineDraggingPboardType];
	[dragTypes addObject:kKTLocalLinkPboardType];
	[outlineView registerForDraggedTypes:dragTypes];
	[outlineView setVerticalMotionCanBeginDrag:YES];
	[outlineView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [outlineView setDraggingSourceOperationMask:NSDragOperationAll_Obsolete forLocal:NO];
	
	
	// Retain the new view
	[outlineView retain];
	[siteOutline release];
	siteOutline = outlineView;
	
	
	// Finally, hook up outline delegate & data source
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewSelectionDidChange:)
												 name:NSOutlineViewSelectionDidChangeNotification
											   object:siteOutline];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(outlineViewItemWillCollapse:)
												 name:NSOutlineViewItemWillCollapseNotification
											   object:siteOutline];
	
	[outlineView setDelegate:mySiteOutlineDataSource];		// -setDelegate: MUST come first to receive all notifications
	[outlineView setDataSource:mySiteOutlineDataSource];
	
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}


@end

