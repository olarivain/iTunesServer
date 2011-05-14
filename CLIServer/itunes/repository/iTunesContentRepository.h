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

- (MMPlaylist*) musicLibrary;
- (MMPlaylist*) movieLibrary;
- (MMPlaylist*) showsLibrary;
- (MMPlaylist*) podcastLibrary;
- (MMPlaylist*) iTunesULibrary;

@end
