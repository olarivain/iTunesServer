//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "iTunesContentRepository.h"
#import "MMContent.h"
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
  NSArray *sources = [iTunes sources];       
  
  // get leaks more than my grand mother, hence the "iterate everything and figure out what you need
  iTunesSource *source;
  for(iTunesSource *temp in sources) 
  {
    if(temp.kind == iTunesESrcLibrary)
    {
      source = temp;
      break;
    }
  }
  return source;
}

- (iTunesPlaylist*) playlistWithSpecialKind: (iTunesESpK) specialKind 
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind
  
  NSArray *playlists = [mainLibrary playlists];

  // get leaks more than my grand mother, hence the "iterate everything and figure out what you need
  iTunesPlaylist *requestedPlaylist;
  for(iTunesPlaylist *temp in playlists)
  {
    if(temp.specialKind == specialKind)
    {
      requestedPlaylist = temp;
      break;
    }
  }
  return requestedPlaylist;
}
  
#pragma mark Concrete accessors (music, movies etc)
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
- (MMServerMediaLibrary*) libraryWithPlaylist: (iTunesPlaylist*) playlist
{
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  MMServerMediaLibrary *library = [assembler createMediaLibrary: playlist];
  return library;
}


- (MMServerMediaLibrary*) tvShowLibrary
{
  iTunesPlaylist *moviesPlaylist = [self shows];
  MMServerMediaLibrary *movies = [self libraryWithPlaylist: moviesPlaylist];  
  return movies;
}

- (MMServerMediaLibrary*) movieLibrary
{
  iTunesPlaylist *moviesPlaylist = [self movies];
  MMServerMediaLibrary *movies = [self libraryWithPlaylist: moviesPlaylist];  
  return movies;
}

- (MMServerMediaLibrary*) musicLibrary
{
  iTunesPlaylist *musicPlaylist = [self music];
  MMServerMediaLibrary *music = [self libraryWithPlaylist: musicPlaylist];  
  return music;
}


@end
