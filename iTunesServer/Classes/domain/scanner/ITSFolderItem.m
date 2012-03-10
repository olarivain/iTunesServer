//
//  ITSFolderItem.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import "ITSFolderItem.h"

@interface ITSFolderItem()
- (id) initWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes;
@end

@implementation ITSFolderItem

@synthesize itemId;
@synthesize name;
@synthesize lastKnownModificationDate;
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
    name = [itemId lastPathComponent];
    [self updateWithAttributes: anAttributes];
  }
  return self;
}

#pragma mark - Update item status
- (void) updateWithAttributes:(NSDictionary *) anAattributes
{
  attributes = anAattributes;
  
  // file is busy, don't touch it
  BOOL busy = [[attributes objectForKey: NSFileBusy] boolValue];
  NSDate *modificationDate = [attributes objectForKey: NSFileModificationDate];
  NSNumber *size = [attributes objectForKey: NSFileSize];
  
  BOOL dateChanged = lastKnownModificationDate == nil ||
                        [modificationDate timeIntervalSinceDate: lastKnownModificationDate] != 0;
  BOOL sizeChanged = lastKnownSize == nil || ![size isEqualToNumber: lastKnownSize];
  
  // file has changed if any of the previous attributes has changed
  // during the first pass, the file will be considered changed, due to stored attributes being nil.
  // this is perfect because we can't make an assumption off the first pass.
  changed = dateChanged || busy || sizeChanged;

  lastKnownSize = size;
  lastKnownModificationDate = modificationDate;
}

#pragma mark - Whether an item still exists on disk
- (BOOL) exists
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath: itemId];
}

#pragma mark - Debug convenience
- (void) logStatus
{
  NSLog(@"file %@ has been changed: %i", itemId, changed);
}

@end
