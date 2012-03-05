//
//  ITSFolderScanner.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <KraCommons/NSArray+BoundSafe.h>
#import "ITSFolderScanner.h"

#import "ITSFolderItemList.h"
#import "ITSFolderItem.h"

#define SCAN_INTERVAL 10

@interface ITSFolderScanner()
- (id) initWithPath: (NSString *) aPath;
- (void) timerFired: (NSTimer *) timer;
- (void) extractDestinationPath;
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
    fileManager = [[NSFileManager alloc] init];
    fileManager.delegate = self;
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
  BOOL isDirectory;
  BOOL exists = [fileManager fileExistsAtPath: aPath isDirectory: &isDirectory];
  if(!exists || !isDirectory)
  {
    NSLog(@"Path %@ is not an existing folder.", aPath);
    return;
  }
  
#warning this isn't exatly thread safe. fix it
  // reset know files, these don't make any more sense now
  folderItemList = [ITSFolderItemList folderItemListWithBasePath: path];
}

- (void) timerFired:(NSTimer *)timer
{
  // make sure another instance of the timer isn't running
  if(isRunning)
  {
    return;
  }
  // lock ourselves for later timer calls
  isRunning = YES;
#if DEBUG_FOLDER_SCANNER == 1
  NSLog(@"Scanning: %@", path);
#endif
  // scan source folder
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
#if DEBUG_FOLDER_SCANNER == 1
    NSLog(@"Adding folder item: %@", itemId);
#endif

    // fetch its attributes and ask folderItemList to update the folder item with them
    NSDictionary *dictionary = [directoryEnumerator fileAttributes];
    [folderItemList addOrUpdateFile: itemId withAttributes: dictionary];
  };
  
  // ask folder item list which folder should be moved
  NSArray *movableItems = [folderItemList folderItemsToMove];
  NSMutableArray *movedItems = [NSMutableArray arrayWithArray: movableItems];
  
  // now move them
  for(ITSFolderItem *item in movableItems)
  {
#if DEBUG_FOLDER_SCANNER == 1
    NSLog(@"Moving %@", item.itemId);
#endif
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
  
  // flip running switch back on
  isRunning = NO;
#if DEBUG_FOLDER_SCANNER == 1
  NSLog(@"Done scanning.");
#endif
  
}

- (void) start
{
  if(destinationPath == nil)
  {
    NSLog(@"*** FATAL no destination path for auto import");
    return;
  }
  
  // make sure we cancel current timer, if any, first
  [self stop];
  
  // then we can start a new timer
  NSLog(@"Starting folder scanner at path: %@", path);
  timer = [NSTimer scheduledTimerWithTimeInterval: 10 
                                           target: self 
                                         selector: @selector(timerFired:) 
                                         userInfo: nil 
                                          repeats: YES];
}

- (void) stop
{
  [timer invalidate];
  timer = nil;
}

@end
