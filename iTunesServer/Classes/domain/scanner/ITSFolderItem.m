//
//  ITSFolderItem.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/NSFileManager.h>
#import "ITSFolderItem.h"

@interface ITSFolderItem()
@property (nonatomic, readwrite) NSString *itemId;
@property (nonatomic, readwrite) NSString *name;
@property (nonatomic, readwrite) NSInteger lastKnownSize;
@property (nonatomic, readwrite) NSDate *lastKnownModificationDate;
@property (nonatomic, readwrite) BOOL changed;
@property (nonatomic, readwrite, copy) NSDictionary *attributes;
@end

@implementation ITSFolderItem


+ (ITSFolderItem *) folderItemWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes
{
	return [[ITSFolderItem alloc] initWithId: anId andAttributes: anAttributes];
}

- (id) initWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes
{
	self = [super init];
	if(self)
	{
		self.itemId = anId;
		self.lastKnownSize = 0;
		self.name = [self.itemId lastPathComponent];
		[self updateWithAttributes: anAttributes];
	}
	return self;
}

#pragma mark - Update item status
- (void) updateWithAttributes:(NSDictionary *) anAattributes
{
	self.attributes = anAattributes;
	
	// file is busy, don't touch it
	BOOL busy = [[self.attributes objectForKey: NSFileBusy] boolValue];
	NSDate *modificationDate = [self.attributes fileModificationDate];
	NSInteger size = [self.attributes fileSize];
	
	BOOL dateChanged = self.lastKnownModificationDate == nil || [modificationDate timeIntervalSinceDate: self.lastKnownModificationDate] != 0;
	BOOL sizeChanged = self.lastKnownSize == 0 || size != self.lastKnownSize;
	
	// file has changed if any of the previous attributes has changed
	// during the first pass, the file will be considered changed, due to stored attributes being nil.
	// this is perfect because we can't make an assumption off the first pass.
	self.changed = dateChanged || busy || sizeChanged;
	
	self.lastKnownSize = size;
	self.lastKnownModificationDate = modificationDate;
}

#pragma mark - Whether an item still exists on disk
- (BOOL) exists
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	return [fileManager fileExistsAtPath: self.itemId];
}

#pragma mark - Debug convenience
- (void) logStatus
{
	DDLogVerbose(@"file %@ has been changed: %i", self.itemId, self.changed);
}

@end
