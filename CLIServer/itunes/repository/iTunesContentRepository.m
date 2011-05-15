//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMServerPlaylist.h>

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

#import "iTunesUtil.h"

@interface iTunesContentRepository()
- (iTunesPlaylist*) music;
- (iTunesPlaylist*) movies;
- (iTunesPlaylist*) shows;
- (iTunesPlaylist*) podcasts;
- (iTunesPlaylist*) iTunesU;

- (iTunesPlaylist*) iTunesPlaylistWithID: (NSString*) persistentId;
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

-(iTunesPlaylist*) iTunesPlaylistWithID: (NSString*) persistentId
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind
  
  NSString *predicateString = [NSString stringWithFormat:@"persistentID == '%@'", persistentId];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *playlists = [[mainLibrary playlists] filteredArrayUsingPredicate: predicate];
  
  return [playlists count] > 0 ? [playlists objectAtIndex:0] : nil;
}

- (MMPlaylist*) playlistWithiTunesPlaylist: (iTunesPlaylist*) playlist
{
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  MMPlaylist *library = [assembler createMediaLibrary: playlist];
  return library;
}

#pragma mark - Repository methods
- (NSArray *) playlistHeaders
{
  iTunesSource *source = [self mainLibrary];
  
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  return [assembler createPlaylistHeaders: source];
}

- (MMPlaylist *) playlistWithPersistentID: (NSString*) persistentID
{
  iTunesPlaylist *iTunesPlaylist = [self iTunesPlaylistWithID: persistentID];
  MMPlaylist *playlist = [self playlistWithiTunesPlaylist: iTunesPlaylist];  
  return playlist;
}

- (MMPlaylist*) podcastLibrary
{
  iTunesPlaylist *podcastPlaylist = [self podcasts];
  MMPlaylist *podcasts = [self playlistWithiTunesPlaylist: podcastPlaylist];  
  return podcasts;
}

- (MMPlaylist*) showsLibrary
{
  iTunesPlaylist *moviesPlaylist = [self shows];
  MMPlaylist *movies = [self playlistWithiTunesPlaylist: moviesPlaylist];  
  return movies;
}

- (MMPlaylist*) movieLibrary
{
  iTunesPlaylist *moviesPlaylist = [self movies];
  MMPlaylist *movies = [self playlistWithiTunesPlaylist: moviesPlaylist];  
  return movies;
}

- (MMPlaylist*) musicLibrary
{
  iTunesPlaylist *musicPlaylist = [self music];
  MMPlaylist *music = [self playlistWithiTunesPlaylist: musicPlaylist];  
  return music;
}

- (MMPlaylist*) iTunesULibrary
{
  iTunesPlaylist *iTunesULibrary = [self iTunesU];
  MMPlaylist *iTunesU = [self playlistWithiTunesPlaylist: iTunesULibrary];  
  return iTunesU;
}


@end
