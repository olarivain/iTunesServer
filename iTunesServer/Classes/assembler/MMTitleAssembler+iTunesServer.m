//
//  MMTitleAssembler+iTunesServer.m
//  iTunesServer
//
//  Created by Olivier Larivain on 3/4/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import <KraCommons/NSDictionary+NilSafe.h>
#import <MediaManagement/MMTitleList.h>
#import <MediaManagement/MMTitle.h>
#import <MediaManagement/MMAudioTrack.h>
#import <MediaManagement/MMSubtitleTrack.h>

#import "MMTitleAssembler+iTunesServer.h"

#import "ITSEncodingRepository.h"

@interface MMTitleAssembler(iTunesServerPrivate)
- (void) updateTitle: (MMTitle *) title withDto: (NSDictionary *) dto;
@end

@implementation MMTitleAssembler (iTunesServer)

- (MMTitleList *) updateTitleListWithDto: (NSDictionary *) dto
{
  ITSEncodingRepository *repository = [ITSEncodingRepository sharedInstance];
  
  NSString *titleListId = [dto nullSafeForKey: @"id"];
  MMTitleList *titleList = [repository titleListWithId: titleListId];
  
  // title list hasn't been scanned yet, so just trust the user's input with it.
  if([titleList.titles count] == 0)
  {
    [self updateTitleList: titleList withDto: dto];
    return titleList;
  }
  
  // otherwise update the title with the selection status from the client
  NSArray *titleDtos = [dto nullSafeForKey: @"titles"];
  for(NSDictionary *titleDto in titleDtos)
  {

    NSInteger titleIndex = [titleDto integerForKey: @"index"];
    MMTitle *title = [titleList titleWithIndex: titleIndex];
    [self updateTitle: title withDto: titleDto];
  }
  return titleList;
}

- (void) updateTitle: (MMTitle *) title withDto: (NSDictionary *) dto
{
  // title is getting encoded, just bail out, we can't update these guys
  if(title.encoding)
  {
    return;
  }
  
  // for all audio track, if the selection status has changed, udpate the title accordingly
  NSArray *audioDtos = [dto nullSafeForKey: @"audioTracks"];
  for(NSDictionary *audioDto in audioDtos)
  {
    BOOL selected = [audioDto integerForKey: @"selected"];
    NSInteger index = [audioDto integerForKey: @"index"];
    MMAudioTrack *audioTrack = [title audioTrackWithIndex: index];
    if(audioTrack.selected != selected)
    {
      [title selectAudioTrack: audioTrack];
    }
  }
  
  // and do the same on the subtitle track
  NSArray *subtitleDtos = [dto nullSafeForKey: @"subtitleTracks"];
  for(NSDictionary *subtitleDto in subtitleDtos)
  {
    BOOL selected = [subtitleDto integerForKey: @"selected"];
    NSInteger index = [dto integerForKey: @"index"];
    MMSubtitleTrack *subtitleTrack = [title subtitleTrackWithIndex: index];
    if(subtitleTrack.selected !=  selected)
    {
      [title selectSubtitleTrack: subtitleTrack];
    }
  }
}

@end
