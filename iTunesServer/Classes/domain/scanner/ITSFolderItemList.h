//
//  ITSFolderItemList.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSFolderItemList : NSObject
{
  __strong NSString *basePath;
  __strong NSMutableArray *items;
}

+ (ITSFolderItemList*) folderItemListWithBasePath: (NSString *) path;

@property (nonatomic, readonly) NSString *basePath;
@property (nonatomic, readonly) NSArray *items;

- (void) udpateBasePath: (NSString *) path;

- (void) addOrUpdateFile: (NSString *) file withAttributes: (NSDictionary *) attributes;
- (NSArray *) folderItemsToMove;
- (void) removeFolderItems: (NSArray *) items;

- (void) removeOrphans;

@end
