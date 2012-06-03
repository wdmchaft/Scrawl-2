#import "MPLoginItems.h"


@implementation MPLoginItems

#pragma mark Methods
+ (NSArray *)loginItems
{
	UInt32 seedValue;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
	
	NSMutableArray *items = [NSMutableArray array];
	for (id item in loginItemsArray)
	{
		NSURL *thePath;
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *)&thePath, NULL) == noErr)
			[items addObject:thePath];
			
	}
	CFRelease(loginItems);
	[loginItemsArray release];
	
	return items;
}
+ (BOOL)loginItemExists:(NSURL *)theURL
{
	NSArray *loginItems = [self loginItems];
	
	BOOL found = NO;
	for (NSURL *item in loginItems)
	{
		if ([[item path] hasPrefix:[theURL path]])
		{
			found = YES;
			break;
		}
	}
	
	return found;
}
+ (void)addLoginItemWithURL:(NSURL *)theURL
{
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, (CFURLRef)theURL, NULL, NULL);		
	if (item)
		CFRelease(item);
}
+ (void)removeLoginItemWithURL:(NSURL *)theURL
{
	UInt32 seedValue;
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	NSArray *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
	for (id item in loginItemsArray)
	{
		NSURL *thePath;
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
		if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef *)&thePath, NULL) == noErr)
		{
			if ([[(NSURL *)thePath path] hasPrefix:[theURL path]])
				LSSharedFileListItemRemove(loginItems, itemRef);
		}
	}
	
	CFRelease(loginItems);
	[loginItemsArray release];
}

@end
