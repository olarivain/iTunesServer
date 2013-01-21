//
//  ITSFolderItem.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSFolderItem : NSObject
{
}

@property (nonatomic, readonly) NSString *itemId;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSInteger lastKnownSize;
@property (nonatomic, readonly) NSDate *lastKnownModificationDate;
@property (nonatomic, readonly) BOOL changed;

+ (ITSFolderItem *) folderItemWithId: (NSString *) anId andAttributes: (NSDictionary *) anAttributes;

- (void) updateWithAttributes: (NSDictionary *) attributes;
- (void) logStatus;
- (BOOL) exists;
@end
