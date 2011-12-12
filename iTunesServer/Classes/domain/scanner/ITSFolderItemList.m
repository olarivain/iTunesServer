//
//  ITSFolderItemList.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSFolderItemList.h"
#import "ITSFolderItem.h"

@interface ITSFolderItemList()
- (id) initWithBasePath: (NSString *) path;
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
    basePath = path;
    items = [NSMutableArray arrayWithCapacity: 20];
  }
  return self;
}

@synthesize basePath;
@synthesize items;

- (void) addOrUpdateFile: (NSString *) file withAttributes: (NSDictionary *) attributes
{
  for(ITSFolderItem *item in items)
  {
    if([item.itemId isEqualToString: file])
    {
      [item updateWithAttributes: attributes];
      return;
    }
  }
  
  ITSFolderItem *item = [ITSFolderItem folderItemWithId: file andAttributes: attributes];
  [items addObject: item];
}

- (void) moveAllFiles
{
  NSLog(@"moving not implemented yet");
}

@end
