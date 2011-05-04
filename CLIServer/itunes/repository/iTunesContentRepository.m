//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMServerMediaLibrary.h>

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

#import "iTunesUtil.h"

@interface iTunesContentRepository()
- (iTunesPlaylist*) music;
- (iTunesPlaylist*) movies;
- (iTunesPlaylist*) shows;
- (iTunesPlaylist*) podcasts;
- (iTunesPlaylist*) iTunesU;
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
  NSArray *sources = [iTunes sources]; 
  
  NSString *predicateString = [NSString stringWithFormat:@"kind == '%@'", iTunesEnumToString(iTunesESrcLibrary)];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *mainSource = [sources filteredArrayUsingPredicate: predicate];

  return [mainSource objectAtIndex:0];
}

- (iTunesPlaylist*) playlistWithSpecialKind: (iTunesESpK) specialKind 
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind

  NSString *predicateString = [NSString stringWithFormat:@"specialKind == '%@'", iTunesEnumToString(specialKind)];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *playlists = [[mainLibrary playlists] filteredArrayUsingPredicate: predicate];
  return [playlists objectAtIndex:0];
}
  
#pragma mark Concrete accessors (music, movies etc)
- (iTunesPlaylist*) music 
{
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKMusic];
  return playlist;
}

- (iTunesPlaylist*) movies 
{
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKMovies];  
  return playlist;
}

- (iTunesPlaylist*) shows 
{
  iTunesPlaylist *playlist = [self playlistWithSpecialKind:iTunesESpKTVShows];
  return playlist;
}

- (iTunesPlaylist*) podcasts 
{
  iTunesPlaylist *podcasts = [self playlistWithSpecialKind:iTunesESpKPodcasts];
  return podcasts;
}

- (iTunesPlaylist*) iTunesU
{
  iTunesPlaylist *iTunesU = [self playlistWithSpecialKind:iTunesESpKITunesU];
  return iTunesU;
}

#pragma mark - Repository methods
- (MMServerMediaLibrary*) libraryWithPlaylist: (iTunesPlaylist*) playlist
{
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  MMServerMediaLibrary *library = [assembler createMediaLibrary: playlist];
  return library;
}

- (MMMediaLibrary*) podcastLibrary
{
  iTunesPlaylist *podcastPlaylist = [self podcasts];
  MMServerMediaLibrary *podcasts = [self libraryWithPlaylist: podcastPlaylist];  
  return podcasts;
}

- (MMMediaLibrary*) showsLibrary
{
  iTunesPlaylist *moviesPlaylist = [self shows];
  MMServerMediaLibrary *movies = [self libraryWithPlaylist: moviesPlaylist];  
  return movies;
}

- (MMMediaLibrary*) movieLibrary
{
  iTunesPlaylist *moviesPlaylist = [self movies];
  MMServerMediaLibrary *movies = [self libraryWithPlaylist: moviesPlaylist];  
  return movies;
}

- (MMMediaLibrary*) musicLibrary
{
  iTunesPlaylist *musicPlaylist = [self music];
  MMServerMediaLibrary *music = [self libraryWithPlaylist: musicPlaylist];  
  return music;
}

- (MMMediaLibrary*) iTunesULibrary
{
  iTunesPlaylist *iTunesULibrary = [self iTunesU];
  MMServerMediaLibrary *iTunesU = [self libraryWithPlaylist: iTunesULibrary];  
  return iTunesU;
}


@end
