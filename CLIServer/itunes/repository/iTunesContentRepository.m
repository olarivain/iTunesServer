//
//  MovieRepository.m
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMGenericPlaylist.h>
#import "iTunes.h"

#import "iTunesContentRepository.h"
#import "ContentAssembler+iTunes.h"

#import "iTunesUtil.h"

#define ITUNES_BUNDLE_IDENTIFIER @"com.apple.iTunes"

@interface iTunesContentRepository()
- (iTunesPlaylist*) iTunesPlaylistWithID: (NSString*) persistentId;
- (iTunesTrack*) trackWithContent: (MMContent*) content;
@end

@implementation iTunesContentRepository

- (id)init
{
  self = [super init];
  if (self) 
  {
    iTunes = [[SBApplication alloc] initWithBundleIdentifier:ITUNES_BUNDLE_IDENTIFIER];
    [iTunes setDelegate: self];
  }
  
  return self;
}

- (void)dealloc
{
  [iTunes dealloc];
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

- (NSArray*) handledPlaylistsSpecialKinds
{
  return [NSArray arrayWithObjects: iTunesEnumToString(iTunesESpKTVShows),
          iTunesEnumToString(iTunesESpKBooks),
          iTunesEnumToString(iTunesESpKITunesU),
          iTunesEnumToString(iTunesESpKMovies),
          iTunesEnumToString(iTunesESpKMusic),
          iTunesEnumToString(iTunesESpKPodcasts), nil];
}

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

- (iTunesTrack*) trackWithContent: (MMContent*) content
{
  iTunesPlaylist *playlist = [self iTunesPlaylistWithID: content.playlistId];
  
  NSString *predicateString = [NSString stringWithFormat:@"persistentID == '%@'", content.contentId];
  NSPredicate *predicate = [NSPredicate predicateWithFormat: predicateString];
  NSArray *tracks = [[playlist tracks] filteredArrayUsingPredicate: predicate];
  
  return [tracks count] > 0 ? [[tracks objectAtIndex:0] get] : nil;

}

#pragma mark - Repository methods
- (NSArray *) playlistHeaders
{
  NSArray *playlists = [self playlists];
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  NSArray *array = [assembler createPlaylistHeaders: playlists];
  
  return array;
}

- (MMPlaylist *) playlistWithPersistentID: (NSString*) persistentID
{
  iTunesPlaylist *iTunesPlaylist = [self iTunesPlaylistWithID: persistentID];
  MMPlaylist *playlist = [self playlistWithiTunesPlaylist: iTunesPlaylist];
  return playlist;
}

- (void) updateContents:(NSArray *)contents
{

  for(MMContent *content in contents)
  {
    BOOL committed = NO;
    int attempt = 0;
    do {
      NSLog(@"Attempt %i", attempt);
      iTunesTrack *track = [self trackWithContent: content];
      if(track == nil)
      {
        NSLog(@"track not found for id : %@", content.contentId);
      }
      track.name = content.name;
      track.comment = content.description;
      
      MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
      iTunesEVdK videoKind = [assembler videoKindFromContentKind: content.kind];
      if(videoKind != -1) 
      {
        track.videoKind = videoKind;
      }
      
      if([content isMusic]) 
      {
        track.artist = content.artist;
        track.album = content.album;
      }
      
      if([content isMovie])
      {
        
      }

      if([content isTvShow])
      {
        track.episodeNumber = [content.episodeNumber intValue];      
        track.seasonNumber = [content.season intValue];
        track.show = content.show;
      }
        
          
      committed = [content.name isEqualToString: track.name];
      attempt++;
    } while(committed && attempt < 5);
  }
}

- (BOOL) isCommitted: (MMContent*) content {
  // sleep
  [NSThread sleepForTimeInterval: 0.2];
  iTunesTrack *track = [self trackWithContent: content];
  
  if(![content.name isEqualToString: track.name]) {
    return NO;
  }
  if(![content.description isEqualToString: track.comment]) {
    return NO;
  }
  
  MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
  iTunesEVdK videoKind = [assembler videoKindFromContentKind: content.kind];
  if(videoKind != -1) 
  {
    if(track.videoKind != videoKind) {
      return NO;
    }
  }
  
  if([content isMusic]) 
  {
    if(![content.artist isEqualToString: track.artist]) {
      return NO;
    }
    
    if(![content.album isEqualToString: content.album]) {
      return NO;
    }
  }
  
  if([content isMovie])
  {
    
  }
  
  if([content isTvShow])
  {
    if(track.episodeNumber != [content.episodeNumber intValue]) {
      return NO;
    }
    if(track.seasonNumber != [content.season intValue]){
      return NO;
    }
    
    if(track.show != content.show) {
      return NO;
    }
  }
  
  return YES;
}

@end
