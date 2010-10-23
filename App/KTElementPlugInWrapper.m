//
//  KTElementPlugInWrapper.m
//  Marvel
//
//  Created by Mike on 26/01/2008.
//  Copyright 2008-2009 Karelia Software. All rights reserved.
//

#import "KTElementPlugInWrapper.h"

#import "SVPlugInGraphicFactory.h"
#import "KT.h"

#import "NSBundle+Karelia.h"
#import "NSString+Karelia.h"

#import "Registration.h"

@implementation KTElementPlugInWrapper

#pragma mark Init & Dealloc

+ (void)load
{
	[self registerPluginClass:[self class] forFileExtension:kKTElementExtension];
}

/*	We only want to load 1.5 and later plugins
 */
+ (BOOL)validateBundle:(NSBundle *)aCandidateBundle
{
	BOOL result = NO;
	
	NSString *minVersion = [aCandidateBundle minimumAppVersion];
	if (minVersion)
	{
		float floatMinVersion = [minVersion floatVersion];
		if (floatMinVersion >= 1.5)
		{
			result = YES;
		}
	}
	
	return result;
}

- (void)dealloc
{
    [_factory release];
	
	[super dealloc];
}

#pragma mark Properties

- (SVGraphicFactory *)graphicFactory;
{
    if (!_factory)
    {
        _factory = [[SVPlugInGraphicFactory alloc] initWithBundle:[self bundle]];
    }
    return _factory;
}

- (KTPluginCategory)category { return [[self pluginPropertyForKey:@"KTCategory"] intValue]; }

- (id)defaultPluginPropertyForKey:(NSString *)key;
{
	if ([key isEqualToString:@"KTElementAllowsIntroduction"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqualToString:@"KTElementSupportsPageUsage"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqualToString:@"KTElementSupportsPageletUsage"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([key isEqualToString:@"KTPageAllowsCallouts"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqualToString:@"KTPageShowSidebar"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([key isEqualToString:@"KTPageAllowsNavigation"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([key isEqualToString:@"KTPageDisableComments"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqualToString:@"KTPageletCanHaveTitle"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([key isEqualToString:@"KTPageSidebarChangeable"])
	{
		return [NSNumber numberWithBool:YES];
	}
	else if ([key isEqualToString:@"KTPageSeparateInspectorSegment"])
	{
		return [NSNumber numberWithBool:NO];
	}
	else if ([key isEqualToString:@"KTPageName"] || [key isEqualToString:@"KTPageletName"])
	{
		return [self pluginPropertyForKey:@"KTPluginName"];
	}
	else if ([key isEqualToString:@"KTPluginUntitledName"])
	{
		return @"";
	}
	else if ([key isEqualToString:@"KTPageUntitledName"] || [key isEqualToString:@"KTPageletUntitledName"])
	{
		return [self pluginPropertyForKey:@"KTPluginUntitledName"];
	}
	else if ([key isEqualToString:@"KTPluginDescription"])
	{
		return @"";
	}
	else if ([key isEqualToString:@"KTPageDescription"] || [key isEqualToString:@"KTPageletDescription"])
	{
		return [self pluginPropertyForKey:@"KTPluginDescription"];
	}
	else if ([key isEqualToString:@"KTPageNibFile"])
	{
		return [self pluginPropertyForKey:@"KTPluginNibFile"];
	}
	else if ([key isEqualToString:@"KTPluginPriority"])
	{
		return [NSNumber numberWithUnsignedInt:5];
	}
	else if ([key isEqualToString:@"KTTemplateName"])
	{
		return @"template";
	}
	else
	{
		return [super defaultPluginPropertyForKey:key];
	}
}

/*
 
 Maybe if I override this, I can easily get a list sorted by priority
 
- (NSComparisonResult)compareTitles:(KSPlugInWrapper *)aPlugin;
{
	return [[self title] caseInsensitiveCompare:[aPlugin title]];
}
*/

#pragma mark -
#pragma mark Plugins List

/*	Returns all registered plugins that are either:
 *		A) Of the svxPage plugin type
 *		B) Of the svxElement plugin type and support page usage
 */
+ (NSSet *)pagePlugins
{
	NSDictionary *pluginDict = [KSPlugInWrapper pluginsWithFileExtension:kKTElementExtension];
	NSMutableSet *buffer = [NSMutableSet setWithCapacity:[pluginDict count]];
	
	NSEnumerator *pluginsEnumerator = [pluginDict objectEnumerator];
	KSPlugInWrapper *aPlugin;
	while (aPlugin = [pluginsEnumerator nextObject])
	{
		if ([[aPlugin pluginPropertyForKey:@"KTElementSupportsPageUsage"] boolValue])
		{
			[buffer addObject:aPlugin];
		}
	}
	
	NSSet *result = [NSSet setWithSet:buffer];
	return result;
}

/*	Returns all registered plugins that are either:
 *		A) Of the svxPagelet plugin type
 *		B) Of the svxElement plugin type and support pagelet usage
 */
+ (NSSet *)pageletPlugins
{
	NSDictionary *pluginDict = [KSPlugInWrapper pluginsWithFileExtension:kKTElementExtension];
	NSMutableSet *buffer = [NSMutableSet setWithCapacity:[pluginDict count]];
	
	NSEnumerator *pluginsEnumerator = [pluginDict objectEnumerator];
	KSPlugInWrapper *aPlugin;
	while (aPlugin = [pluginsEnumerator nextObject])
	{
		if ([[aPlugin pluginPropertyForKey:@"KTElementSupportsPageletUsage"] boolValue])
		{
			[buffer addObject:aPlugin];
		}
	}
	
	NSSet *result = [NSSet setWithSet:buffer];
	return result;
}

#pragma mark Collection Presets

+ (NSDictionary *)emptyCollectionPreset;
{
    NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
                            NSLocalizedString(@"Empty Collection", "toolbar menu"), @"KTPresetTitle",
                            [NSNumber numberWithInt:0], @"KTPluginPriority",
							[NSImage imageNamed:@"toolbar_collection.tiff" ], @"KTPluginIcon",	// indicator of the actual icon
                            nil];
    
    return result;
}


+ (void)populateMenuWithCollectionPresets:(NSMenu *)aMenu atIndex:(NSUInteger)index;
{
    NSMutableDictionary *dictOfPresets = [NSMutableDictionary dictionary];
    [dictOfPresets setObject:[self emptyCollectionPreset] forKey:@"0"];
	
    
    // Go through and get the localized names of each bundle, and put into a dict keyed by name
    NSDictionary *plugins = [KSPlugInWrapper pluginsWithFileExtension:kKTElementExtension];
    NSEnumerator *enumerator = [plugins objectEnumerator];	// go through each plugin.
    KTElementPlugInWrapper *plugin;
    
	while (plugin = [enumerator nextObject])
	{
		NSBundle *bundle = [plugin bundle];
		
		NSArray *presets = [bundle objectForInfoDictionaryKey:@"KTPresets"];
		NSEnumerator *presetEnum = [presets objectEnumerator];
		NSDictionary *presetDict;
		
		while (nil != (presetDict = [presetEnum nextObject]) )
		{
            int priority = 5;		// default if unspecified (RichText=1, Photo=2, other=5, Advanced HTML = 9
            id priorityID = [presetDict objectForKey:@"KTPluginPriority"];
            if (nil != priorityID)
            {
                priority = [priorityID intValue];
            } 
            if (priority > 0	// don't add zero-priority items to menu!
                && (priority < 9 || gIsPro || (nil == gRegistrationString)) )	// only if non-advanced or advanced allowed.
            {
                NSString *englishPresetTitle = [presetDict objectForKey:@"KTPresetTitle"];
                NSString *presetTitle = [bundle localizedStringForKey:englishPresetTitle value:englishPresetTitle table:nil];
                
                NSMutableDictionary *newPreset = [presetDict mutableCopy];
                [newPreset setObject:[bundle bundleIdentifier] forKey:@"KTPresetIndexBundleIdentifier"];
                
                [dictOfPresets setObject:newPreset
                                  forKey:[NSString stringWithFormat:@"%d %@", priority, presetTitle]];
                
                [newPreset release];
            }
		}
	}
	
	// Now add the sorted arrays
	NSArray *sortedPriorityNames = [[dictOfPresets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	NSEnumerator *sortedEnum = [sortedPriorityNames objectEnumerator];
	NSString *priorityAndName;
	
	while (nil != (priorityAndName = [sortedEnum nextObject]) )
	{
		NSDictionary *presetDict = [dictOfPresets objectForKey:priorityAndName];
		NSString *bundleIdentifier = [presetDict objectForKey:@"KTPresetIndexBundleIdentifier"];
		
		KTElementPlugInWrapper *plugin = (bundleIdentifier ?
                                          [self pluginWithIdentifier:bundleIdentifier] :
                                          nil);
		
        NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
		
		NSString *presetTitle = [presetDict objectForKey:@"KTPresetTitle"];
        if (plugin) presetTitle = [[plugin bundle] localizedStringForKey:presetTitle
                                                                   value:presetTitle
                                                                   table:nil];
        
		id priorityID = [presetDict objectForKey:@"KTPluginPriority"];
		int priority = 5;
		if (nil != priorityID)
		{
			priority = [priorityID intValue];
		} 
		
		
        NSImage *image = nil;
		
		if (plugin)
		{
			image = [[plugin graphicFactory] icon];
#ifdef DEBUG
			if (nil == image)
			{
				NSLog(@"nil pluginIcon for %@", presetTitle);
			}
#endif
		}
		else	// built-in, no bundle, so try to get icon directly
		{
			image = [presetDict objectForKey:@"KTPluginIcon"];
		}
        if (image)
        {
            
            [image setDataRetained:YES];	// allow image to be scaled.
            [image setScalesWhenResized:YES];
            [image setSize:NSMakeSize(32.0f, 32.0f)];
            [menuItem setImage:image];
        }
        
        [menuItem setTitle:presetTitle];
				
		// set target/action
		[menuItem setRepresentedObject:presetDict];
		[menuItem setAction:@selector(addCollection:)];
		
		[aMenu insertItem:menuItem atIndex:index];  index++;
	}
}

@end
