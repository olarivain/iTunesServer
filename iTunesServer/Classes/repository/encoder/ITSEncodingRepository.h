//
//  ITSEncodingRepository.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/26/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMTitleList;

@interface ITSEncodingRepository : NSObject 
{
  __strong NSMutableArray *availableResource;
}

+ (ITSEncodingRepository *) sharedInstance;

- (NSArray *) availableTitleLists;
- (MMTitleList *) titleListWithId: (NSString *) titleListId;
@end
