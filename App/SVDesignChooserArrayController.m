//
//  SVDesignChooserArrayController.m
//  Sandvox
//
//  Created by Dan Wood on 5/7/10.
//  Copyright 2010 Karelia Software. All rights reserved.
//

#import "SVDesignChooserArrayController.h"
#import "KTDesign.h"

@implementation SVDesignChooserArrayController

- (NSArray *)arrangeObjects:(NSArray *)objects;
{
    objects = [super arrangeObjects:objects];		// do the filtering
	objects = [KTDesign consolidateDesignsIntoFamilies:objects];	// consolidate
	return objects;
}

@end

