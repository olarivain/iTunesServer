//
//  ITSFolderScanner.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <KraCommons/NSArray+BoundSafe.h>
#import <MediaManagement/MMTitle.h>

#import "ITSFolderScanner.h"

#import "ITSFolderItemList.h"
#import "ITSFolderItem.h"

#import "ITSEncodingRepository.h"
#import "ITSEncoder.h"

#define SCAN_INTERVAL 60

@interface ITSFolderScanner()
- (id) initWithPath: (NSString *) aPath;
- (void) timerFired: (NSTimer *) timer;
- (void) extractDestinationPath;
- (void) updateFolderItemList;
- (void) moveFolderItems;
@end

@implementation ITSFolderScanner

+ (ITSFolderScanner *) folderScannerWithScannedPath: (NSString *) aPath {
  return [[ITSFolderScanner alloc] initWithPath: aPath];
}

- (id) initWithPath: (NSString *) aPath
{
  self = [super init];
  if(self)
  {
    stopped = YES;
    [self setScannedPath: aPath];
    
    [self extractDestinationPath];
  }
  return self;
}

- (void) extractDestinationPath
{
  // kindly ask itunes for it's DB locatin, from there we'll derive the Auto import folder
  CFArrayRef recentLibraries = CFPreferencesCopyAppValue((CFStringRef)@"iTunesRecentDatabasePaths",(CFStringRef)@"com.apple.iApps");
  NSArray *libraryPaths = (__bridge NSArray*)recentLibraries;
  NSString *libraryPath = [libraryPaths boundSafeObjectAtIndex: 0];
  
  CFRelease(recentLibraries);
  
  // path is invalid, get the hell out
  if(libraryPath == nil)
  {
    [self setScannedPath: nil];
    return;
  }
  
  // build destination path
  NSString *libraryFolder = [[libraryPath stringByExpandingTildeInPath] stringByDeletingLastPathComponent];
  NSString *automaticallyImportPath = [NSString stringWithFormat: @"%@/iTunes Music/Automatically Add to iTunes/", libraryFolder];
  
  // ask file manager if destination exists and is a folder, if not, get the hell out
  BOOL isFolder = NO;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if(![fileManager fileExistsAtPath: automaticallyImportPath isDirectory: &isFolder] && !isFolder)
  {
      
    automaticallyImportPath = [NSString stringWithFormat: @"%@/iTunes Media/Automatically Add to iTunes/", libraryFolder];
    if(![fileManager fileExistsAtPath: automaticallyImportPath isDirectory: &isFolder] && !isFolder)
    {
      automaticallyImportPath = [NSString stringWithFormat: @"%@/iTunes Media/Automatically Add to iTunes.localized/", libraryFolder];
      if(![fileManager fileExistsAtPath: automaticallyImportPath isDirectory: &isFolder] && !isFolder)
      {
        [self setScannedPath: nil];
        return;
      }
    }
  }
  
  // Now, we can set the destination path
  destinationPath = automaticallyImportPath;
}

- (void) setScannedPath:(NSString *)aPath
{
  // no changes, get the hell out
  if(aPath == path)
  {
    return;
  }
  
  path = aPath;
  
  // first, make sure the path exists and is a folder
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDirectory;
  BOOL exists = [fileManager fileExistsAtPath: aPath isDirectory: &isDirectory];
  if(!exists || !isDirectory)
  {
    NSLog(@"Path %@ is not an existing folder.", aPath);
    return;
  }
  
  // create folder item list if we don't have one already
  if(folderItemList == nil) 
  {
    folderItemList = [ITSFolderItemList folderItemListWithBasePath: path];
  }
  else
  {
    // otherwise reset it with the new base path
    // this will drop all existing folder items
    [folderItemList udpateBasePath: path];
  }
}

#pragma mark - Scanning folder for items
- (void) updateFolderItemList 
{
  // Fetch the encoded list so we can implicitely skip all titles that are currently getting encoded
  ITSEncoder *encoder = [ITSEncoder sharedEncoder];
  MMTitle *activeTitle = encoder.activeTitle;
  
  // scan source folder
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath: path];
  NSString *file;
  while(file = [directoryEnumerator nextObject])
  {
    // just ignore dot file
    if ([file hasPrefix: @"."])
    {
      continue;
    }
    
    // grab next file
    NSString *itemId = [NSString stringWithFormat:@"%@/%@", path, file];
    
    // file is currently getting encoded, skip it too
    if([itemId caseInsensitiveCompare: activeTitle.targetPath] == NSOrderedSame)
    {
      continue;
    }
    
    // fetch its attributes and ask folderItemList to update the folder item with them
    NSDictionary *dictionary = [directoryEnumerator fileAttributes];
    [folderItemList addOrUpdateFile: itemId withAttributes: dictionary];
  }
}

#pragma mark - Moving relevant items to the destination
- (void) moveFolderItems
{
  // ask folder item list which folder should be moved
  NSArray *movableItems = [folderItemList folderItemsToMove];
  NSMutableArray *movedItems = [NSMutableArray arrayWithArray: movableItems];
  
  // now move them
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for(ITSFolderItem *item in movableItems)
  {
    
    NSLog(@"Moving %@", item.itemId);
    // move item with file manager
    NSError *error = nil;
    NSString *fullDestinationPath = [NSString stringWithFormat:@"%@/%@", destinationPath, item.name];
    [fileManager moveItemAtPath: item.itemId toPath: fullDestinationPath error: &error];
    // log error if any
    if(error)
    {
      NSLog(@"*** FATAL *** Could not move item %@", item.itemId);
      NSLog(@"%@", error.localizedDescription);
    }
    else 
    {
      [movedItems addObject: item];
    }
  }
  
  // don't forget to remove moved items
  [folderItemList removeFolderItems: movedItems];
  
  // remove items that don't exist anymore
  [folderItemList removeOrphans];
  
}

#pragma mark - Timer firing
- (void) timerFired:(NSTimer *)timer
{
  // make sure another instance of the timer isn't running
  @synchronized(self)
  {
    // stopped is here to prevent race conditions in case the timer got fired at the same time the 
    // scanner was stopped.
    if(isRunning || stopped)
    {
      return;
    } 
    
    // lock ourselves for later timer calls
    isRunning = YES;
  }
  
  // refresh folder item list
  [self updateFolderItemList];
  
  // move items if needed
  [self moveFolderItems];
  
  // flip running switch back on
  isRunning = NO;
}

#pragma mark - Start Stop the scanner
- (void) start
{
  if(destinationPath == nil)
  {
    NSLog(@"*** FATAL no destination path for auto import");
    return;
  }
  
  // make sure we cancel current timer, if any, first
  [self stop];
  
  stopped = NO;
  
  // then we can start a new timer
  NSLog(@"Starting folder scanner at path: %@", path);
  timer = [NSTimer scheduledTimerWithTimeInterval: SCAN_INTERVAL
                                           target: self 
                                         selector: @selector(timerFired:) 
                                         userInfo: nil 
                                          repeats: YES];
}

- (void) stop
{
  @synchronized(self)
  {
    stopped = YES;
    [timer invalidate];
    timer = nil;
  }
}

@end
