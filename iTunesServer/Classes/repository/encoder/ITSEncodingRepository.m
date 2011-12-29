//
//  ITSEncodingRepository.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/26/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import "ITSEncodingRepository.h"

#import "ITSConfigurationRepository.h"
#import "ITSConfiguration.h"

static ITSEncodingRepository *sharedInstance;


@interface ITSEncodingRepository()
- (void) findResourcesAtPath: (NSString *) path withResult: (NSMutableArray *) result;
- (BOOL) isDVDAtPath: (NSString *) path;
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

- (NSArray *) availableResources
{
  ITSConfiguration *configuration = [[ITSConfigurationRepository sharedInstance] readConfiguration];
  
  NSMutableArray *resources = [NSMutableArray arrayWithCapacity: 10];
  [self findResourcesAtPath: configuration.encodingResourcePath withResult: resources];
  return resources;
}

- (void) findResourcesAtPath: (NSString *) path withResult: (NSMutableArray *) result 
{
  // make sure input makes sense
  if([path length] == 0)
  {
    return;
  }
  
  // first, check if path is a dvd folder
  if([self isDVDAtPath: path])
  {
    // it is, add the folder to the resources and GTFO
    [result addObject: path];
    return;
  }
  
  // it isn't, list everything below, skip dot files and recurse on folders
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error = nil;
  NSArray *subPaths = [fileManager contentsOfDirectoryAtPath: path error: &error];
  
  // an error happened, just get ouf of here, not much we can do anyway.
  if(error)
  {
    NSLog(@"Error happened while looking for encodable resources at path %@: %@", path, error.localizedDescription);
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
      [self findResourcesAtPath: fullPath withResult: result];
      continue;
    }
    
    // otherwise, just add file
    [result addObject: fullPath];
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
    NSLog(@"Error happened while looking for DVD folder at path %@: %@", path, error.localizedDescription);
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
