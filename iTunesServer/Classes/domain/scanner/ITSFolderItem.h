//
//  ITSFolderItem.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSFolderItem : NSObject 
{
  __strong NSDictionary *attributes;
  
  __strong NSString *itemId;
  __strong NSString *name;
  __strong NSDate *lastKnownModificationDate;
  
  __strong NSString *destionationPath;
  
  NSNumber *lastKnownSize;
  
  BOOL changed;
}

@property (nonatomic, readonly) NSString *itemId;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSNumber *lastKnownSize;
@property (nonatomic, readonly) NSDate *lastKnownModificationDate;
@property (nonatomic, readonly) BOOL changed;

+ (ITSFolderItem *) folderItemWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes;

- (void) updateWithAttributes: (NSDictionary *) attributes;
- (void) logStatus;

@end
