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
- (iTunesPlaylist*) iTunesPlaylistWithID: (NSString*) persistentId andApp: (iTunesApplication*) app;
@end

@implementation iTunesContentRepository

- (id)init
{
  self = [super init];
  if (self) 
  {
  }
  
  return self;
}

- (void)dealloc
{
  [super dealloc];
}
   
#pragma mark - SBApplicationDelegate method
- (id) eventDidFail: (const AppleEvent *) event withError: (NSError *) error 
{
  NSLog(@"An event failed %@", error);
  return nil;
}

#pragma mark - basic accessor to library
- (iTunesSource *)mainLibraryWithApp: (iTunesApplication*) iTunes
{
  NSArray *sources = [iTunes sources]; 
  
  NSString *predicateString = [NSString stringWithFormat:@"kind == %@", iTunesEnumToString(iTunesESrcLibrary)];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *mainSource = [sources filteredArrayUsingPredicate: predicate];

  return [mainSource objectAtIndex:0];
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

- (NSArray *) playlistsWithApp: (iTunesApplication*) iTunes;
{
  iTunesSource *mainLibrary = [self mainLibraryWithApp: iTunes];
  
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

-(iTunesPlaylist*) iTunesPlaylistWithID: (NSString*) persistentId andApp: (iTunesApplication*) iTunes
{
  iTunesSource *mainLibrary = [self mainLibraryWithApp: iTunes];
  
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
  iTunesApplication *iTunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
  [iTunes setDelegate: self];
  
  NSArray *playlists = [self playlistsWithApp: iTunes];
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  NSArray *array = [assembler createPlaylistHeaders: playlists];
  
  [iTunes release];
  return array;
}

- (MMPlaylist *) playlistWithPersistentID: (NSString*) persistentID
{
  iTunesApplication *iTunes = [[SBApplication alloc] initWithBundleIdentifier:@"com.apple.iTunes"];
  [iTunes setDelegate: self];
  
  iTunesPlaylist *iTunesPlaylist = [self iTunesPlaylistWithID: persistentID andApp: iTunes];
  MMPlaylist *playlist = [self playlistWithiTunesPlaylist: iTunesPlaylist];

  [iTunes release];

  return playlist;
}

@end
