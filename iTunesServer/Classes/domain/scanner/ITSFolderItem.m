//
//  ITSFolderItem.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSFolderItem.h"

@interface ITSFolderItem()
- (id) initWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes;
@end

@implementation ITSFolderItem

@synthesize itemId;
@synthesize lastModificationDate;
@synthesize lastKnownSize;
@synthesize changed;

+ (ITSFolderItem *) folderItemWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes
{
  return [[ITSFolderItem alloc] initWithId: anId andAttributes: anAttributes];
}

- (id) initWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes
{
  self = [super init];
  if(self)
  {
    itemId = anId;
    [self updateWithAttributes: anAttributes];
  }
  return self;
}

- (void) updateWithAttributes:(NSDictionary *) anAattributes
{
  attributes = anAattributes;
  
  // TODO: do verification here, and update values
  changed = YES;
}

@end
