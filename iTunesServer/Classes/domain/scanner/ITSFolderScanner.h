//
//  ITSFolderScanner.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSFolderItemList;

@interface ITSFolderScanner : NSObject<NSFileManagerDelegate>
{
  __strong NSFileManager *fileManager;
  __strong ITSFolderItemList *folderItemList;
  __strong NSTimer *timer;
  __strong NSString *path;
}

- (void) start;
- (void) stop;

- (void) setScannedPath: (NSString *) aPath;

@end
