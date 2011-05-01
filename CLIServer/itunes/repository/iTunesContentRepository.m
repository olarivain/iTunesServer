//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "iTunesContentRepository.h"
#import "Content.h"
#import "ContentAssembler+iTunes.h"


@interface iTunesContentRepository()
- (iTunesPlaylist*) music;
- (iTunesPlaylist*) movies;
- (iTunesPlaylist*) shows;
- (iTunesPlaylist*) playlistWithSpecialKind: (iTunesESpK) specialKind;
@end

@implementation iTunesContentRepository

- (id)init
{
  self = [super init];
  if (self) {
    iTunes = [[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"] retain];
    [iTunes setDelegate: self];
  }
  
  return self;
}

- (void)dealloc
{
  [iTunes release];
  [super dealloc];
}
   
#pragma mark - SBApplicationDelegate method
- (id) eventDidFail: (const AppleEvent *) event withError: (NSError *) error 
{
  NSLog(@"An event failed");
  return nil;
}

#pragma mark - basic accessor to library
- (iTunesSource *)mainLibrary 
{
  // TODO: this is worth stress testing I guess, cause it's actually dereferencing everything
  NSArray *sources = [[iTunes sources] get];       
  // filter libraries agains the main one (iTunesESrcLibrary)
  NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"kind == %i", iTunesESrcLibrary];
  NSArray *libraries = [sources filteredArrayUsingPredicate: filterPredicate];
  
  // if we still have at least one object left, return it
  if ([libraries count] == 0) 
  {
    return nil;
  }
  
  iTunesSource *source = [[libraries objectAtIndex:0] get];
  return source;
}

- (iTunesPlaylist*) playlistWithSpecialKind: (iTunesESpK) specialKind 
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind
  NSArray *playlists = [[mainLibrary playlists] get];
  NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"specialKind == %i", specialKind];
  NSArray *playlist = [playlists filteredArrayUsingPredicate: filterPredicate];
  
  if([playlist count] == 0) 
  {
    return nil;
  }
  
  iTunesPlaylist *requestedPlaylist = [[playlist objectAtIndex:0] get];
  NSLog(@"request playlist is : %u",   [[requestedPlaylist tracks] count]);
  return requestedPlaylist;
}
  

- (iTunesPlaylist*) music {
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKMusic];
  return playlist;
}

- (iTunesPlaylist*) movies {
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKMovies];  
  return playlist;
}

- (iTunesPlaylist*) shows {
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKTVShows];
  return playlist;
}

#pragma mark - Repository methods

- (NSArray*) contentArrayWithPlaylist: (iTunesPlaylist*) playlist;
{
  NSLog(@"Assembler begin");
  
  
  ContentAssembler *assembler = [ContentAssembler sharedInstance];
  NSArray *array = [assembler createContentListWithPlaylist: playlist];
    NSLog(@"Assembler end");
  return array;
}

- (NSArray*) allMovies
{
  iTunesPlaylist *moviesPlaylist = [self movies];
  NSArray *movies = [self contentArrayWithPlaylist: moviesPlaylist];
  return  movies;  
}

- (NSArray*) allMusic
{
  NSLog(@"allMusic begin");
  iTunesPlaylist *musicPlaylist = [self music];
  NSArray *music = [self contentArrayWithPlaylist: musicPlaylist];
  NSLog(@"allMusic end");
  return music;
}

- (NSArray*) allPodcasts
{
  return [NSArray array];
}

- (NSArray*) alliTunesU
{
  return [NSArray array];
}


@end
