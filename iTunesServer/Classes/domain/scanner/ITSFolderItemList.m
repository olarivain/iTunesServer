//
//  ITSFolderItemList.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import "ITSFolderItemList.h"
#import "ITSFolderItem.h"

@interface ITSFolderItemList() {
	__strong NSMutableArray *_items;
}
@property (nonatomic, strong, readwrite) NSString *basePath;
@end

@implementation ITSFolderItemList

+ (ITSFolderItemList*) folderItemListWithBasePath: (NSString *) path
{
	return [[ITSFolderItemList alloc] initWithBasePath: path];
}

- (id) initWithBasePath: (NSString *) path
{
	self = [super init];
	if(self)
	{
		self.basePath = path;
		_items = [NSMutableArray arrayWithCapacity: 20];
	}
	return self;
}

#pragma mark - Moving the scanned path
- (void) udpateBasePath: (NSString *) path
{
	[_items removeAllObjects];
	self.basePath = path;
}

#pragma mark - File item list manipulation
- (void) addOrUpdateFile: (NSString *) file withAttributes: (NSDictionary *) attributes
{
	for(ITSFolderItem *item in self.items)
	{
		if([item.itemId isEqualToString: file])
		{
			[item updateWithAttributes: attributes];
			return;
		}
	}
	
	ITSFolderItem *item = [ITSFolderItem folderItemWithId: file andAttributes: attributes];
	[_items addObject: item];
}


- (NSArray *) folderItemsToMove
{
	NSMutableArray *movableItems = [NSMutableArray arrayWithCapacity: self.items.count];
	for(ITSFolderItem *item in self.items)
	{
		if(item.changed)
		{
			continue;
		}
		[movableItems addObject: item];
	}
	
	return movableItems;
}

- (void) removeFolderItems: (NSArray *) removedItems
{
	for(ITSFolderItem *item in removedItems)
	{
		[_items removeObject: item];
	}
}

#pragma mark - Clean up task
- (void) removeOrphans
{
	NSArray *allItems = [NSArray arrayWithArray: self.items];
	// remove items that don't exist anymore
	for(ITSFolderItem *item in allItems)
	{
		if(![item exists])
		{
			[_items removeObject: item];
		}
	}
}

@end
