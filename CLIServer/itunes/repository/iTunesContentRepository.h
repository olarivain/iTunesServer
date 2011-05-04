//
//  MovieRepository.h
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
@class MMMediaLibrary;

@interface iTunesContentRepository : NSObject<SBApplicationDelegate>
{
@private
  iTunesApplication *iTunes;    
}

- (MMMediaLibrary*) musicLibrary;
- (MMMediaLibrary*) movieLibrary;
- (MMMediaLibrary*) showsLibrary;
- (MMMediaLibrary*) podcastLibrary;

@end
