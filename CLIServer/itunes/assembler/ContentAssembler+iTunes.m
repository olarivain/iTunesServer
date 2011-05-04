//
//  ContentAssembler+iTunes.m
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ContentAssembler+iTunes.h"
#import "MMContent.h"
#import "MMServerMediaLibrary.h"

@interface MMContentAssembler()
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind;
@end

@implementation MMContentAssembler(iTunes)

#pragma mark - iTunes to MediaManagement objects
- (MMServerMediaLibrary*) createMediaLibrary: (iTunesPlaylist*) playlist
{

  SBElementArray *tracks = [playlist tracks];
  
  NSArray *ids = [tracks arrayByApplyingSelector:@selector(persistentID)];
  NSArray *names = [tracks arrayByApplyingSelector:@selector(name)];
  NSArray *genres =[tracks arrayByApplyingSelector:@selector(genre)];
  NSArray *albums = [tracks arrayByApplyingSelector:@selector(album)];
  NSArray *artists =[tracks arrayByApplyingSelector:@selector(artist)];
  NSArray *trackNumbers = [tracks arrayByApplyingSelector:@selector(trackNumber)];
  NSArray *descriptions = [tracks arrayByApplyingSelector:@selector(objectDescription)];
  NSArray *shows = [tracks arrayByApplyingSelector:@selector(show)];
  NSArray *episodes = [tracks arrayByApplyingSelector:@selector(episodeNumber)];
  
  MMContentKind contentKind = [self contentKindFromiTunesSpecialKind: playlist.specialKind];
  MMServerMediaLibrary *library = [MMServerMediaLibrary mediaLibraryWithContentKind: contentKind andSize: [ids count]];
  
  for(int i = 0; i < [ids count]; i++)
  {
    MMContent *content = [MMContent content: contentKind];
    content.contentId = [ids objectAtIndex:i];
    content.name = [names objectAtIndex:i];
    content.genre = [genres objectAtIndex:i];
    content.album = [albums objectAtIndex:i];
    content.artist = [artists objectAtIndex:i];
    content.trackNumber = [[trackNumbers objectAtIndex:i] intValue];
    content.description = [descriptions objectAtIndex:i];
    content.show = [shows objectAtIndex:i];
    content.episodeNumber = [[episodes objectAtIndex:i] intValue];
    [library addContent: content];
  }
  return library;
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
