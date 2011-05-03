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

- (NSArray*) createContentListWithPlaylist:(iTunesPlaylist *)playlist {
  // grab all tracks, instantiate content array with a relevant capacity and then convert all those guys.
  NSArray *tracks = [[playlist tracks] get];
  NSMutableArray *array = [NSMutableArray arrayWithCapacity:[tracks count]];
  
  iTunesESpK specialKind = [playlist specialKind];
  for(iTunesTrack *track in tracks)
  {
    MMContent *content = [self createContentWithiTunesItem:track andSpecialKind:specialKind];
    [array addObject:content];
  }
  return array;
}

- (MMContent*) createContentWithiTunesItem: (iTunesTrack*) item andSpecialKind: (MMContentKind) kind
{
//  MMContentKind kind = [self contentKindFromiTunesSpecialKind: specialKind];
  MMContent *content = [MMContent content: kind];
  int retaincount = [item retainCount];
  if(retaincount != 1)
  {
    NSLog(@"I have one %i", retaincount);
    [item release];
  }
//  content.contentId = [item persistentID];
//  content.name = [item name]; 
//  content.genre = [item genre];
//  if(kind == MUSIC) {
//    content.album = [item album];
//    content.artist = [item artist];
//    content.trackNumber = [item trackNumber];
//  }
//  
//  if(kind == TV_SHOW || kind == MOVIE) 
//  {
//    content.description = [item objectDescription];
//  }
//  
//  if(kind == TV_SHOW) 
//  {
//    content.show = [item show];
//    content.episodeNumber = [item episodeNumber];
//    content.season = [item seasonNumber];
//  }
  
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
