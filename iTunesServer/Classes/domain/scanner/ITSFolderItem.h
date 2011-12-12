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
  __strong NSDate *lastModificationDate;
  
  NSInteger lastKnownSize;
  
  BOOL changed;
}

@property (nonatomic, readonly) NSString *itemId;
@property (nonatomic, readonly) NSInteger lastKnownSize;
@property (nonatomic, readonly) NSDate *lastModificationDate;
@property (nonatomic, readonly) BOOL changed;

+ (ITSFolderItem *) folderItemWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes;

- (void) updateWithAttributes: (NSDictionary *) attributes;

@end
