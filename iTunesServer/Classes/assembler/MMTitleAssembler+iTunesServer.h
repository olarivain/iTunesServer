//
//  MMTitleAssembler+iTunesServer.h
//  iTunesServer
//
//  Created by Olivier Larivain on 3/4/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import <MediaManagement/MMTitleAssembler.h>

@class MMTitleList;

@interface MMTitleAssembler (iTunesServer)

- (MMTitleList *) updateTitleListWithDto: (NSDictionary *) dto;

@end
