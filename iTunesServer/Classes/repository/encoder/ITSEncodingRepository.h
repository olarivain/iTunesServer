//
//  ITSEncodingRepository.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/26/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSEncodingRepository : NSObject

+ (ITSEncodingRepository *) sharedInstance;

- (NSArray *) availableTitleLists;

@end
