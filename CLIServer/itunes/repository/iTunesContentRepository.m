//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMGenericPlaylist.h>

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

#import "iTunesUtil.h"

@interface iTunesContentRepository()
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
  NSLog(@"An event failed %@", error);
  return nil;
}

#pragma mark - basic accessor to library
- (iTunesSource *)mainLibrary 
{
  NSArray *sources = [iTunes sources]; 
  
  NSString *predicateString = [NSString stringWithFormat:@"kind == %@", iTunesEnumToString(iTunesESrcLibrary)];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *mainSource = [sources filteredArrayUsingPredicate: predicate];

  return [mainSource objectAtIndex:0];
}

- (iTunesPlaylist*) playlistWithSpecialKind: (iTunesESpK) specialKind 
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind
  NSString *predicateString = [NSString stringWithFormat:@"specialKind == %@", iTunesEnumToString(specialKind)];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *playlists = [[mainLibrary playlists] filteredArrayUsingPredicate: predicate];
  return [playlists objectAtIndex:0];
}

- (NSArray*) handledPlaylistsSpecialKinds
{
  return [NSArray arrayWithObjects: iTunesEnumToString(iTunesESpKTVShows),
          iTunesEnumToString(iTunesESpKBooks),
          iTunesEnumToString(iTunesESpKITunesU),
          iTunesEnumToString(iTunesESpKMovies),
          iTunesEnumToString(iTunesESpKMusic),
          iTunesEnumToString(iTunesESpKPodcasts), nil];
}

//- (NSString *)

- (NSArray *) playlists
{
  iTunesSource *mainLibrary = [self mainLibrary];
  
  // get playlist list and filter it agains the requested special kind
  NSMutableString *predicateTemplate = [NSMutableString string];
  NSArray *kinds = [self handledPlaylistsSpecialKinds];
  for(NSString *kind in kinds)
  {
    [predicateTemplate appendFormat: @"specialKind == %@", kind];
    if(kind != [kinds lastObject])
    {
      [predicateTemplate appendString:@" OR "];
    }
  }
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateTemplate];
  NSArray *playlists = [[mainLibrary playlists] filteredArrayUsingPredicate: predicate];
  return playlists;
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
  NSArray *playlists = [self playlists];
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  return [assembler createPlaylistHeaders: playlists];
}

- (MMPlaylist *) playlistWithPersistentID: (NSString*) persistentID
{
  iTunesPlaylist *iTunesPlaylist = [self iTunesPlaylistWithID: persistentID];
  MMPlaylist *playlist = [self playlistWithiTunesPlaylist: iTunesPlaylist];  
  return playlist;
}

@end
