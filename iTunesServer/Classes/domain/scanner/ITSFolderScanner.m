//
//  ITSFolderScanner.m
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#define SCAN_INTERVAL 10
#import "ITSFolderScanner.h"

#import "ITSFolderItemList.h"

@interface ITSFolderScanner()
- (void) timerFired: (NSTimer *) timer;
@end

@implementation ITSFolderScanner

- (id) init
{
  self = [super init];
  if(self)
  {
    fileManager = [[NSFileManager alloc] init];
    fileManager.delegate = self;
  }
  return self;
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
  NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath: path];
  NSString *file;
  while(file = [directoryEnumerator nextObject])
  {
    NSDictionary *dictionary = [directoryEnumerator fileAttributes];
    [folderItemList addOrUpdateFile: file withAttributes: dictionary];
  };
  
  [folderItemList moveAllFiles];
}

- (void) start
{
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
