//
//  ContentAssembler+iTunes.m
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMServerMediaLibrary.h>

#import "ContentAssembler+iTunes.h"

#import "iTunesTracksWrapper.h"

@interface MMContentAssembler()
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind;
@end

@implementation MMContentAssembler(iTunes)

#pragma mark - iTunes to MediaManagement objects
- (MMServerMediaLibrary*) createMediaLibrary: (iTunesPlaylist*) playlist
{

  SBElementArray *tracks = [playlist tracks];
  
  iTunesTracksWrapper *wrapper = [iTunesTracksWrapper wrapper];
  
  wrapper.ids = [tracks arrayByApplyingSelector:@selector(persistentID)];
  wrapper.names = [tracks arrayByApplyingSelector:@selector(name)];
  wrapper.genres =[tracks arrayByApplyingSelector:@selector(genre)];
  wrapper.albums = [tracks arrayByApplyingSelector:@selector(album)];
  wrapper.artists =[tracks arrayByApplyingSelector:@selector(artist)];
  wrapper.trackNumbers = [tracks arrayByApplyingSelector:@selector(trackNumber)];
  wrapper.descriptions = [tracks arrayByApplyingSelector:@selector(objectDescription)];
  wrapper.shows = [tracks arrayByApplyingSelector:@selector(show)];
  wrapper.episodes = [tracks arrayByApplyingSelector:@selector(episodeNumber)];
  
  NSUInteger count = [wrapper count];
  
  MMContentKind contentKind = [self contentKindFromiTunesSpecialKind: playlist.specialKind];
  MMServerMediaLibrary *library = [MMServerMediaLibrary mediaLibraryWithContentKind: contentKind andSize: count];
  
  for(int i = 0; i < count; i++)
  {
    MMContent *content = [MMContent content: contentKind];
    content.contentId = [wrapper idForIndex:i]; 
    content.name = [wrapper nameForIndex:i];
    content.genre = [wrapper genreForIndex:i];
    content.album = [wrapper albumForIndex:i];
    content.artist = [wrapper artistForIndex:i];
    content.trackNumber = [wrapper trackNumberForIndex:i];
    content.description = [wrapper descriptionForIndex:i];
    content.show = [wrapper showForIndex:i];
    content.season = [wrapper seasonForIndex:i];
    content.episodeNumber = [wrapper episodeForIndex:i];
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
