//
//  MMTitleAssembler+iTunesServer.m
//  iTunesServer
//
//  Created by Olivier Larivain on 3/4/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import <MediaManagement/MMTitleList.h>
#import <MediaManagement/MMTitle.h>
#import <MediaManagement/MMAudioTrack.h>
#import <MediaManagement/MMSubtitleTrack.h>

#import "MMTitleAssembler+iTunesServer.h"

#import "ITSEncodingRepository.h"

@interface MMTitleAssembler(iTunesServerPrivate)
- (void) updateTitle: (MMTitle *) title WithSelectionDto: (NSDictionary *) dto;
@end

@implementation MMTitleAssembler (iTunesServer)

#pragma mark - Updates an MMTitleList with selection status
- (void) updateTitleList: (MMTitleList *) titleList withSelectionDto: (NSDictionary *) dto
{
	// update the title with the selection status from the client
	NSArray *titleDtos = [dto nullSafeForKey: @"titles"];
	for(NSDictionary *titleDto in titleDtos)
	{
		
		NSInteger titleIndex = [titleDto integerForKey: @"index"];
		MMTitle *title = [titleList titleWithIndex: titleIndex];
		[self updateTitle: title WithSelectionDto: titleDto];
	}
}

- (void) updateTitle: (MMTitle *) title WithSelectionDto: (NSDictionary *) dto
{
	// title is getting encoded, just bail out, we can't update this guy
	if(title.encoding)
	{
		return;
	}
	
	// for all audio track, if the selection status has changed, udpate the title accordingly
	NSArray *audioDtos = [dto nullSafeForKey: @"audioTracks"];
	for(NSDictionary *audioDto in audioDtos)
	{
		// fetch appropriate audio track
		NSInteger index = [audioDto integerForKey: @"index"];
		MMAudioTrack *audioTrack = [title audioTrackWithIndex: index];
		
		// and flip selection switch
		BOOL selected = [audioDto integerForKey: @"selected"];
		if(audioTrack.selected != selected)
		{
			[title selectAudioTrack: audioTrack];
		}
	}
	
	// and do the same on the subtitle track
	NSArray *subtitleDtos = [dto nullSafeForKey: @"subtitleTracks"];
	for(NSDictionary *subtitleDto in subtitleDtos)
	{
		// fetch appropriate subtitle track
		NSInteger index = [subtitleDto integerForKey: @"index"];
		MMSubtitleTrack *subtitleTrack = [title subtitleTrackWithIndex: index];
		
		// and flip selection switch appropriately
		BOOL selected = [subtitleDto integerForKey: @"selected"];
		if(subtitleTrack.selected !=  selected)
		{
			[title selectSubtitleTrack: subtitleTrack];
		}
	}
    
	// reset the completed/encoding flags
	if(title.selected) {
		title.completed = NO;
		title.encoding = NO;
	}
}

@end
