//
//  ContentAssembler+iTunes.h
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import "MMContentAssembler.h"
@class MMiTunesMediaLibrary;

@interface MMContentAssembler(iTunes)
- (MMiTunesMediaLibrary*) createMediaLibrary: (iTunesPlaylist*) playlist;
- (NSArray*) createContentListWithPlaylist: (iTunesPlaylist*) playlist;
- (MMContent*) createContentWithiTunesItem: (iTunesItem*) item andSpecialKind: (iTunesESpK) specialKind;
@end
