//
//  SVDocContentViewController.m
//  Marvel
//
//  Created by Mike on 17/08/2009.
//  Copyright 2009 Karelia Software. All rights reserved.
//

#import "SVWebContentAreaController.h"
#import "SVWebViewLoadController.h"


@implementation SVWebContentAreaController

- (id)init
{
    [super init];
    
    _webViewController = [[SVWebViewLoadController alloc] init];
    [self setViewControllers:[NSArray arrayWithObject:_webViewController]
               selectedIndex:0];
    
    return self;
}

- (void)dealloc
{
    [_webViewController release];
    [_selectedPages release];
    
    [super dealloc];
}

#pragma mark Pages

- (NSArray *)selectedPages { return _selectedPages; }

- (void)setSelectedPages:(NSArray *)pages
{
    pages = [pages copy];
    [_selectedPages release];
    _selectedPages = pages;
    
    // Update subcontrollers
    switch ([pages count])
    {
        case 0:
            [[self webViewLoadController] setPage:nil];
            break;
        case 1:
            [[self webViewLoadController] setPage:[pages objectAtIndex:0]];
            break;
        default:
            // TODO: display "Multiple pages selected" placeholder instead of webview
            break;
    }
}

#pragma mark View controllers

@synthesize webViewLoadController = _webViewController;

- (IBAction)updateWebView:(id)sender;
{
    [[self viewControllers] makeObjectsPerformSelector:@selector(updateWebView:)
                                            withObject:sender];
}

@end
