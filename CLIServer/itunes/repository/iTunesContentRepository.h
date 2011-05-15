//
//  MovieRepository.h
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
@class MMPlaylist;

@interface iTunesContentRepository : NSObject<SBApplicationDelegate>
{
@private
  iTunesApplication *iTunes;    
}

- (NSArray *) playlistHeaders;
- (MMPlaylist*) playlistWithPersistentID: (NSString *) persistentID;

@end
