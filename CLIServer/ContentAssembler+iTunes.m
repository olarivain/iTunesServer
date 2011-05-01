//
//  ContentAssembler+iTunes.m
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ContentAssembler+iTunes.h"
#import "Content.h"

@interface ContentAssembler()
- (ContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind;
@end

@implementation ContentAssembler(iTunes)

- (Content*) createContentWithiTunesItem: (iTunesTrack*) item andSpecialKind: (iTunesESpK) specialKind
{
  ContentKind kind = [self contentKindFromiTunesSpecialKind: specialKind];
  Content *content = [Content content: kind];
  
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

- (ContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind {
  ContentKind kind;
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
