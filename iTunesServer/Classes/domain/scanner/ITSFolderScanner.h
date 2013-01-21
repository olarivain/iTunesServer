//
//  ITSFolderScanner.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSFolderItemList;

@interface ITSFolderScanner : NSObject<NSFileManagerDelegate>
{
	__strong ITSFolderItemList *folderItemList;
	__strong NSTimer *timer;
	__strong NSString *path;
	__strong NSString *destinationPath;
	BOOL isRunning;
	BOOL stopped;
}

+ (ITSFolderScanner *) folderScannerWithScannedPath: (NSString *) aPath;

- (void) start;
- (void) stop;

- (void) setScannedPath: (NSString *) aPath;

@end
