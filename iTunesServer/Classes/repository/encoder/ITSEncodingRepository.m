//
//  ITSEncodingRepository.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/26/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <MediaManagement/MMTitleList.h>

#import "ITSEncodingRepository.h"

#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

static ITSEncodingRepository *sharedInstance;


@interface ITSEncodingRepository()
- (void) findResourcesAtPath: (NSString *) path;
- (void) removeOrphanWithPath: (NSString *) path;
- (BOOL) isDVDAtPath: (NSString *) path;
- (void) addTitleToAvailableResources: (MMTitleList *) titleList;
@end

@implementation ITSEncodingRepository

+ (ITSEncodingRepository *) sharedInstance
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[ITSEncodingRepository alloc] init];
	});
	return sharedInstance;
}

- (id) init
{
	self = [super init];
	if (self)
	{
		availableResource = [NSMutableArray arrayWithCapacity: 10];
	}
	return self;
}

#pragma mark - Fetching a title list with a given id
- (MMTitleList *) titleListWithId: (NSString *) titleListId
{
	// first, reset the available title list
	[self availableTitleLists];
	
	for(MMTitleList *titleList in availableResource)
	{
		if([titleList.titleListId isEqualToString: titleListId])
		{
			return titleList;
		}
	}
	
	return nil;
}

#pragma mark - Finding available title lists
- (NSArray *) availableTitleLists
{
	ITSConfiguration *configuration = [[ITSConfigurationRepository sharedInstance] readConfiguration];
	
	@synchronized(self)
	{
		[self findResourcesAtPath: configuration.encodingResourcePath];
	}
	return availableResource;
}

#pragma mark - deleting orphan resources
- (void) removeOrphanWithPath:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableArray *orphans = [NSMutableArray arrayWithCapacity: [availableResource count]];
	// iterate all existing resources
	for(MMTitleList *orphanCandidate in availableResource)
	{
		BOOL isFolder = NO;
		BOOL exists = [fileManager fileExistsAtPath: orphanCandidate.titleListId isDirectory: &isFolder];
		// if path doesn't exist anymore, then add it to the orphan list
		if(!exists)
		{
			[orphans addObject: orphanCandidate];
		}
	}
	
	// finally, remove all orphans from available resources
	[availableResource removeObjectsInArray: orphans];
}

#pragma mark - Adding a title list to the available list
- (void) addTitleToAvailableResources: (MMTitleList *) titleList
{
	if([availableResource containsObject: titleList])
	{
		return;
	}
	[availableResource addObject: titleList];
}

#pragma mark - Scanning target folder
- (void) findResourcesAtPath: (NSString *) path
{
	// make sure input makes sense
	if([path length] == 0)
	{
		return;
	}
	
	[self removeOrphanWithPath: path];
	
	// first, check if path is a dvd folder
	if([self isDVDAtPath: path])
	{
		// it is, add the folder to the resources and GTFO
		MMTitleList *titleList = [MMTitleList titleListWithId: path];
		[self addTitleToAvailableResources: titleList];
		return;
	}
	
	// it isn't, list everything below, skip dot files and recurse on folders
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *subPaths = [fileManager contentsOfDirectoryAtPath: path error: &error];
	
	// an error happened, just get ouf of here, not much we can do anyway.
	if(error)
	{
		DDLogInfo(@"Error happened while looking for encodable resources at path %@: %@", path, error.localizedDescription);
		return;
	}
	
	// now go through each element. We have to do this in two passes to find VIDEO_TS folders (DVDs) first.
	for(NSString *subPath in subPaths)
	{
		// skip dot files
		if([subPath hasPrefix: @"."])
		{
			continue;
		}
		
		// we have to work against full path, -contentsOfDirectoryAtPath:error: returns relative path to its parent,
		// hence rebuild the full path here and use that going forward.
		NSString *fullPath = [NSString pathWithComponents:[NSArray arrayWithObjects: path, subPath, nil]];
		
		BOOL isFolder = NO;
		BOOL exists = [fileManager fileExistsAtPath: fullPath isDirectory: &isFolder];
		BOOL isPackage = [[NSWorkspace sharedWorkspace] isFilePackageAtPath: fullPath];
		
		// sounds weird that exists would be false, but it can't hurt to check.
		// skip if file doesn't exist.
		if(!exists)
		{
			continue;
		}
		
		// recurse on folders/packages, don't add folder to result
		if(isFolder || isPackage)
		{
			[self findResourcesAtPath: fullPath];
			continue;
		}
		
		// otherwise, just add file
		MMTitleList *titleList = [MMTitleList titleListWithId: fullPath];
		[self addTitleToAvailableResources: titleList];
	}
}

- (BOOL) isDVDAtPath: (NSString *) path
{
	// first, list path content
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *content = [fileManager contentsOfDirectoryAtPath: path error: &error];
	
	// an error happened, just get ouf of here, not much we can do anyway.
	if(error)
	{
		DDLogInfo(@"Error happened while looking for DVD folder at path %@: %@", path, error.localizedDescription);
		return NO;
	}
	
	// first path, check if it is a dvd
	for(NSString *subPath in content)
	{
		// skip dot files
		if([subPath hasPrefix: @"."])
		{
			continue;
		}
		
		// we have to work against full path, -contentsOfDirectoryAtPath:error: returns relative path to its parent,
		// hence rebuild the full path here and use that going forward.
		NSString *fullPath = [NSString pathWithComponents:[NSArray arrayWithObjects: path, subPath, nil]];
		
		BOOL isFolder = NO;
		[fileManager fileExistsAtPath: fullPath isDirectory: &isFolder];
		// this is a DVD folder, flag as such and exit, no point in continuing here
		if([subPath caseInsensitiveCompare: @"VIDEO_TS"] == NSOrderedSame && isFolder)
		{
			return YES;
		}
	}
	return NO;
}

@end
