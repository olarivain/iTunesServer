//
//  ITSEncoder.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/25/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "hb.h"

@class MMTitleList;
@class MMTitle;

@interface ITSEncoder : NSObject
{
}

+ (ITSEncoder *) sharedEncoder;

@property (nonatomic, strong, readonly) MMTitle *activeTitle;

- (MMTitleList *) scanPath: (NSString *) path;
- (NSError *) deleteResource: (NSString *) resource;

- (void) scheduleTitleList: (MMTitleList *) titleList;

- (void) closeLibHB;


@end
