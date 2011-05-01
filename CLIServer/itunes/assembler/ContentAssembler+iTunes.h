//
//  ContentAssembler+iTunes.h
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import "ContentAssembler.h"

@interface ContentAssembler(iTunes)
- (NSArray*) createContentListWithPlaylist: (iTunesPlaylist*) playlist;
- (Content*) createContentWithiTunesItem: (iTunesItem*) item andSpecialKind: (iTunesESpK) specialKind;

@end
