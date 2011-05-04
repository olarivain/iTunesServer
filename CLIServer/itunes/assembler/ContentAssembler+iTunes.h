//
//  ContentAssembler+iTunes.h
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"
#import <MediaManagement/MMContentAssembler.h>
#import <MediaManagement/MMContent.h>

@class MMServerMediaLibrary;

@interface MMContentAssembler(iTunes)
- (MMServerMediaLibrary*) createMediaLibrary: (iTunesPlaylist*) playlist;
@end
