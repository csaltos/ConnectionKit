//
//  SVPageletBodyTextAreaController.m
//  Sandvox
//
//  Created by Mike on 14/10/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import "SVBodyTextDOMController.h"
#import "SVParagraphDOMController.h"

#import "KT.h"
#import "SVBodyTextHTMLContext.h"
#import "SVCallout.h"
#import "KTAbstractPage.h"
#import "SVGraphic.h"
#import "SVBody.h"
#import "KTDocWindowController.h"
#import "SVImage.h"
#import "SVLinkManager.h"
#import "SVLink.h"
#import "SVMediaRecord.h"
#import "SVTextAttachment.h"
#import "SVWebContentObjectsController.h"

#import "NSDictionary+Karelia.h"
#import "DOMNode+Karelia.h"
#import "DOMRange+Karelia.h"

#import "KSOrderedManagedObjectControllers.h"


static NSString *sBodyTextObservationContext = @"SVBodyTextObservationContext";


@implementation SVBodyTextDOMController

#pragma mark Init & Dealloc

- (id)initWithContentObject:(SVContentObject *)body inDOMDocument:(DOMDocument *)document;
{
    // Super
    self = [super initWithContentObject:body inDOMDocument:document];
    
    
    // Keep an eye on model
    [body addObserver:self forKeyPath:@"string" options:0 context:sBodyTextObservationContext];
    
    
    // Create controller for each graphic/attachment
    NSSet *graphics = [[self representedObject] attachments];
    for (SVTextAttachment *anAttachment in graphics)
    {
        SVGraphic *graphic = [anAttachment pagelet];
        Class class = [graphic DOMControllerClass];
        SVDOMController *result = [[class alloc] initWithContentObject:graphic
                                                         inDOMDocument:document];
        
        [result setHTMLContext:[[self webEditorViewController] HTMLContext]];
        
        [self addChildWebEditorItem:result];
        [result release];
    }
    
    
    // Finish up
    return self;
}

- (void)dealloc
{
    [[self representedObject] removeObserver:self forKeyPath:@"string"];
    
    // Release ivars
    
    [super dealloc];
}

#pragma mark DOM Node

- (void)setHTMLElement:(DOMHTMLElement *)element
{
    [super setHTMLElement:element];
    [self setTextHTMLElement:element];
}

#pragma mark Content

- (void)update
{
    [self willUpdate];
    
    [self didUpdate];
}

#pragma mark Insertion

- (void)insertGraphic:(SVGraphic *)graphic;
{
    SVWebEditorView *webEditor = [self webEditor];
    
    
    // Create text attachment for the graphic
    SVTextAttachment *textAttachment = [NSEntityDescription insertNewObjectForEntityForName:@"TextAttachment"
                                                                     inManagedObjectContext:[graphic managedObjectContext]];
    [textAttachment setPagelet:graphic];
    [textAttachment setBody:[self representedObject]];
    
    
    // Create controller for graphic
    SVDOMController *controller = [[[graphic DOMControllerClass] alloc]
                                   initWithHTMLDocument:(DOMHTMLDocument *)[webEditor HTMLDocument]];
    [controller setHTMLContext:[self HTMLContext]];
    [controller setRepresentedObject:graphic];
    
    [self addChildWebEditorItem:controller];
    [controller release];
    
    
    // Generate DOM node
    [webEditor willChange];
    
    DOMRange *selection = [webEditor selectedDOMRange];
    [selection insertNode:[controller HTMLElement]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[webEditor webView]];
}

- (IBAction)insertPagelet:(id)sender;
{
    // TODO: Make the insertion
}

- (IBAction)insertFile:(id)sender;
{
    NSWindow *window = [[[self HTMLElement] documentView] window];
    NSOpenPanel *panel = [[window windowController] makeChooseDialog];
    
    [panel beginSheetForDirectory:nil file:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(chooseDialogDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)chooseDialogDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSCancelButton) return;
    
    
    NSManagedObjectContext *context = [[self representedObject] managedObjectContext];
    SVMediaRecord *media = [SVMediaRecord mediaWithURL:[sheet URL]
                                            entityName:@"ImageMedia"
                        insertIntoManagedObjectContext:context
                                                 error:NULL];
    
    if (media)
    {
        SVImage *image = [SVImage insertNewImageWithMedia:media];
        [self insertGraphic:image];
    }
    else
    {
        NSBeep();
    }
}

#pragma mark Placement/Wrap

- (void)placeDOMElementAtBlockLevel:(DOMElement *)element;
{
    // Shift the element up in the tree until it is a child of our own element
    DOMNode *parentNode = [element parentNode];
    while (parentNode != [self HTMLElement])
    {
        DOMNode *refNode = parentNode;
        parentNode = [parentNode parentNode];
        [parentNode insertBefore:element refChild:refNode];
    }
}

- (IBAction)wrapLeft:(id)sender;
{
    SVWebEditorItem *controller = [[self webEditor] selectedItem];
    [self placeDOMElementAtBlockLevel:[controller HTMLElement]];
    
    SVGraphic *graphic = [controller representedObject];
    [graphic setWrap:SVContentObjectWrapBlockLeft];
    
    // Trigger processing of the change
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[[self webEditor] webView]];
}

- (IBAction)wrapCenter:(id)sender;
{
    SVWebEditorItem *controller = [[self webEditor] selectedItem];
    [self placeDOMElementAtBlockLevel:[controller HTMLElement]];
    
    SVGraphic *graphic = [controller representedObject];
    [graphic setWrap:SVContentObjectWrapBlockCenter];
    
    // Trigger processing of the change
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[[self webEditor] webView]];
}

- (IBAction)wrapRight:(id)sender;
{
    SVWebEditorItem *controller = [[self webEditor] selectedItem];
    [self placeDOMElementAtBlockLevel:[controller HTMLElement]];
    
    SVGraphic *graphic = [controller representedObject];
    [graphic setWrap:SVContentObjectWrapBlockRight];
    
    // Trigger processing of the change
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[[self webEditor] webView]];
}

- (IBAction)wrapFloatLeft:(id)sender;
{
    SVWebEditorItem *controller = [[self webEditor] selectedItem];
    [self placeDOMElementAtBlockLevel:[controller HTMLElement]];
    
    SVGraphic *graphic = [controller representedObject];
    [graphic setWrap:SVContentObjectWrapFloatLeft];
    
    // Trigger processing of the change
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[[self webEditor] webView]];
}

- (IBAction)wrapFloatRight:(id)sender;
{
    SVWebEditorItem *controller = [[self webEditor] selectedItem];
    [self placeDOMElementAtBlockLevel:[controller HTMLElement]];
    
    SVGraphic *graphic = [controller representedObject];
    [graphic setWrap:SVContentObjectWrapFloatRight];
    
    // Trigger processing of the change
    [[NSNotificationCenter defaultCenter] postNotificationName:WebViewDidChangeNotification
                                                        object:[[self webEditor] webView]];
}


#pragma mark Editability

- (BOOL)isSelectable { return NO; }

- (void)setEditable:(BOOL)editable
{
    // TODO: Embedded graphics must NOT be selectable
    for (SVDOMController *aGraphicController in [self graphicControllers])
    {
        [[[aGraphicController HTMLElement] style] setProperty:@"-webkit-user-select"
                                                        value:@"none"
                                                     priority:@"!important"];
    }
    
    // Carry on
    [super setEditable:editable];
}

#pragma mark Subcontrollers

- (SVDOMController *)controllerForBodyElement:(SVBodyElement *)element;
{
    SVDOMController * result = nil;
    for (result in [self childWebEditorItems])
    {
        if ([result representedObject] == element) break;
    }
    
    return result;
}

- (SVDOMController *)controllerForDOMNode:(DOMNode *)node;
{
    SVDOMController *result = nil;
    for (result in [self childWebEditorItems])
    {
        if ([node isDescendantOfNode:[result HTMLElement]]) break;
    }
             
    return result;
}

- (NSArray *)graphicControllers;
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[[self childWebEditorItems] count]];
    
    for (KSDOMController *aController in [self childWebEditorItems])
    {
        if (![aController isKindOfClass:[SVParagraphDOMController class]])
        {
            [result addObject:aController];
        }
    }
    
    return result;
}

#pragma mark Updates

@synthesize updating = _isUpdating;

- (void)willUpdate
{
    OBPRECONDITION(!_isUpdating);
    _isUpdating = YES;
}

- (void)didUpdate
{
    OBPRECONDITION(_isUpdating);
    _isUpdating = NO;
}

#pragma mark Editing

- (void)didChangeText;
{
    //  Body Text Controller doesn't track indivdual text changes itself, leaving that up to the paragraphs. So use this point to pass a similar message onto those subcontrollers to handle.
    
    
    NSMutableString *html = [[NSMutableString alloc] init];
    SVBodyTextHTMLContext *context = [[SVBodyTextHTMLContext alloc] initWithStringStream:html];
    [context setBodyTextDOMController:self];
    
    [[self textHTMLElement] writeInnerHTMLToContext:context];
    [context release];
    
    
    SVBody *body = [self representedObject];
    if (![html isEqualToString:[body string]])
    {
        [super didChangeText];
        
        _isUpdating = YES;
        [body setString:html];
        _isUpdating = NO;
    }
    
    [html release];
}

- (void)writeGraphicController:(SVDOMController *)controller
                     toContext:(SVBodyTextHTMLContext *)context;
{
    SVGraphic *graphic = [controller representedObject];
    
    
    // Ensure graphic has TextAttachment
    SVTextAttachment *textAttachment = [graphic textAttachment];
    if (!textAttachment)
    {
        textAttachment = [NSEntityDescription insertNewObjectForEntityForName:@"TextAttachment"
                                                       inManagedObjectContext:[graphic managedObjectContext]];
        [textAttachment setPagelet:graphic];
        [textAttachment setBody:[self representedObject]];
    }
    
    
    // Set attachment location
    NSMutableString *stream = (NSMutableString *)[context stringStream];
    [context writeString:[NSString stringWithUnichar:NSAttachmentCharacter]];
    
    [textAttachment setLocation:[NSNumber numberWithUnsignedInteger:([stream length] - 1)]];
    [textAttachment setLength:[NSNumber numberWithShort:1]];
}

#pragma mark Links

- (void)changeLinkDestinationTo:(NSString *)linkURLString;
{
    SVWebEditorView *webEditor = [self webEditor];
    DOMRange *selection = [webEditor selectedDOMRange];
    
    if (!linkURLString)
    {
        DOMHTMLAnchorElement *anchor = [selection editableAnchorElement];
        if (anchor)
        {
            // Figure out selection before editing the DOM
            DOMNode *remainder = [anchor unlink];
            [selection selectNode:remainder];
            [webEditor setSelectedDOMRange:selection affinity:NSSelectionAffinityDownstream];
        }
        else
        {
            // Fallback way
            [[webEditor selectedDOMRange] removeAnchorElements];
        }
    }
    else
    {
        DOMHTMLAnchorElement *link = (id)[[webEditor HTMLDocument] createElement:@"A"];
        [link setHref:linkURLString];
        
        // Changing link affects selection. But if the selection is collapsed the user almost certainly wants to affect surrounding word/link
        if ([selection collapsed])
        {
            [[webEditor webView] selectWord:self];
            selection = [webEditor selectedDOMRange];
        }
        
        [selection surroundContents:link];
        
        // Make the link the selected object
        [selection selectNode:link];
        [webEditor setSelectedDOMRange:selection affinity:NSSelectionAffinityDownstream];
    }
    
    // Need to let paragraph's controller know an actual editing change was made
    [self webViewDidChange];
}

- (void)changeLink:(SVLinkManager *)sender;
{
    [self changeLinkDestinationTo:[[sender selectedLink] URLString]];
}

@synthesize selectedLink = _selectedLink;

- (void)webEditorTextDidChangeSelection:(NSNotification *)notification
{
    [super webEditorTextDidChangeSelection:notification];
    
    
    // Does the selection contain a link? If so, make it the selected object
    SVWebEditorView *webEditor = [self webEditor];
    DOMRange *selection = [webEditor selectedDOMRange];
    DOMHTMLAnchorElement *anchorElement = [selection editableAnchorElement];
    
    SVLink *link = nil;
    if (anchorElement)
    {
        // Is it a page link?
        NSString *linkURLString = [anchorElement getAttribute:@"href"]; // -href will give the URL a scheme etc. if there's no base URL
        if ([linkURLString hasPrefix:kKTPageIDDesignator])
        {
            NSString *pageID = [linkURLString substringFromIndex:[kKTPageIDDesignator length]];
            KTAbstractPage *target = [KTAbstractPage pageWithUniqueID:pageID
                                               inManagedObjectContext:[[self representedObject] managedObjectContext]];
            
            if (target)
            {
                link = [[SVLink alloc] initWithPage:target
                                    openInNewWindow:[[anchorElement target] isEqualToString:@"_blank"]];
            }
        }
        
        // Not a page link? Fallback to regular link
        if (!link)
        {
            link = [[SVLink alloc] initWithURLString:linkURLString
                                     openInNewWindow:[[anchorElement target] isEqualToString:@"_blank"]];
        }
    }
    
    [[SVLinkManager sharedLinkManager] setSelectedLink:link editable:(selection != nil)];
    [link release];
}

#pragma mark Dragging

- (void)webEditorTextValidateDrop:(id <NSDraggingInfo>)info
                proposedOperation:(NSDragOperation *)proposedOperation;
{
    // When dragging graphics within the Web Editor, want to move them rather than do a copy
    SVWebEditorView *webEditor = [self webEditor];
    if ([info draggingSource] == webEditor)
    {
        *proposedOperation = NSDragOperationMove;
        
        // Only inline graphics should use drag caret
        NSArray *items = [webEditor selectedItems];
        for (SVWebEditorItem *anItem in items)
        {
            SVGraphic *graphic = [anItem representedObject];
            if (![[graphic wrap] isEqualToNumber:SVContentObjectWrapNone])
            {
                [webEditor removeDragCaret];
                break;
            }
        }
    }
    else
    {
        return [super webEditorTextValidateDrop:info proposedOperation:proposedOperation];
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == sBodyTextObservationContext)
    {
        if (![self isUpdating])
        {
            [[self webEditorViewController] setNeedsUpdate];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end


#pragma mark -


@implementation SVWebEditorView (SVBodyTextActions)

- (IBAction)wrapLeft:(id)sender;
{
    [[self selectedItem] doCommandBySelector:_cmd];
}

- (IBAction)wrapCenter:(id)sender;
{
    [[self selectedItem] doCommandBySelector:_cmd];
}

- (IBAction)wrapRight:(id)sender;
{
    [[self selectedItem] doCommandBySelector:_cmd];
}

- (IBAction)wrapFloatLeft:(id)sender;
{
    [[self selectedItem] doCommandBySelector:_cmd];
}

- (IBAction)wrapFloatRight:(id)sender;
{
    [[self selectedItem] doCommandBySelector:_cmd];
}

@end
