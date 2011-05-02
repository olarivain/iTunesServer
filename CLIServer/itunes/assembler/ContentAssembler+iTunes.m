//
//  ContentAssembler+iTunes.m
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ContentAssembler+iTunes.h"
#import "MMContent.h"
#import "MMiTunesMediaLibrary.h"

@interface MMContentAssembler()
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind;
@end

@implementation MMContentAssembler(iTunes)

#pragma mark - iTunes to MediaManagement objects
- (MMiTunesMediaLibrary*) createMediaLibrary: (iTunesPlaylist*) playlist
{
  NSArray *tracks = [[playlist tracks] get];
  
  MMContentKind contentKind = [self contentKindFromiTunesSpecialKind: playlist.specialKind];
  MMiTunesMediaLibrary *library = [MMiTunesMediaLibrary mediaLibraryWithContentKind: contentKind andSize: [tracks count]];
  
  
  // TODO: this is ridiculously slow, I'll have to figure out a way to make it faster
  iTunesESpK specialKind = [playlist specialKind];
  for(SBObject *trackObject in tracks)
  {
    iTunesTrack *track = [trackObject get];
    MMContent *content = [self createContentWithiTunesItem:track andSpecialKind:specialKind];
    [library addContent:content];
  }
  
  return library;
}

- (NSArray*) createContentListWithPlaylist:(iTunesPlaylist *)playlist {
  // grab all tracks, instantiate content array with a relevant capacity and then convert all those guys.
  NSArray *tracks = [[playlist tracks] get];
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:[tracks count]];
  
  iTunesESpK specialKind = [playlist specialKind];
  for(SBObject *trackObject in tracks)
  {
    iTunesTrack *track = [trackObject get];
    MMContent *content = [self createContentWithiTunesItem:track andSpecialKind:specialKind];
    [array addObject:content];
  }
  return array;
}

- (MMContent*) createContentWithiTunesItem: (iTunesTrack*) item andSpecialKind: (iTunesESpK) specialKind
{
  MMContentKind kind = [self contentKindFromiTunesSpecialKind: specialKind];
  MMContent *content = [MMContent content: kind];
  
  content.contentId = [item persistentID];
  content.name = [item name]; 
  content.genre = [item genre];
  if(kind == MUSIC) {
    content.album = [item album];
    content.artist = [item artist];
    content.trackNumber = [item trackNumber];
  }
  
  if(kind == TV_SHOW || kind == MOVIE) 
  {
    content.description = [item objectDescription];
  }
  
  if(kind == TV_SHOW) 
  {
    content.show = [item show];
    content.episodeNumber = [item episodeNumber];
    content.season = [item seasonNumber];
  }
  
  return content;
}

#pragma mark - Enum converter
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind {
  MMContentKind kind;
  switch(specialKind) {

    case iTunesESpKITunesU:
      kind = ITUNES_U;
      break;
    case iTunesESpKMovies:
      kind = MOVIE;
      break;
    case iTunesESpKMusic:
      kind = MUSIC;
      break;
    case iTunesESpKPodcasts:
      kind = PODCAST;
      break;
    case iTunesESpKTVShows:
      kind = TV_SHOW;
      break;     
    default:
      kind = UNKNOWN;
      break;
  }
  return kind;
}

@end
