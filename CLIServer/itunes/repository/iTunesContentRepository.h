//
//  MovieRepository.h
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ScriptingBridge/ScriptingBridge.h>

@class MMPlaylist;
@class iTunesApplication;

@interface iTunesContentRepository : NSObject<SBApplicationDelegate>
{
  iTunesApplication *iTunes;
}

- (NSArray *) playlistHeaders;
- (MMPlaylist*) playlistWithPersistentID: (NSString *) persistentID;
- (void) updateContents: (NSArray*) contents;
@end
