//
//  ContentAssembler+iTunes.m
//  CLIServer
//
//  Created by Kra on 4/30/11.
//  Copyright 2011 kra. All rights reserved.
//
#import <MediaManagement/MMContent.h>
#import <MediaManagement/MMGenericPlaylist.h>

#import "MMContentAssembler+iTunes.h"

#import "ITSiTunesWrapper.h"
#import "iTunes.h"

@interface MMContentAssembler(iTunesPrivate)
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind;
@end

@implementation MMContentAssembler(iTunes)

#pragma mark - iTunes to MediaManagement objects

- (NSArray *) createPlaylistHeaders: (NSArray *) iTunesPlaylists
{
	NSMutableArray *playlists = [NSMutableArray arrayWithCapacity: [iTunesPlaylists count]];
	for(iTunesPlaylist *iTunesPlaylist in iTunesPlaylists)
	{
		iTunesESpK iTunesKind = iTunesPlaylist.specialKind;
		MMContentKind contentKind = [self contentKindFromiTunesSpecialKind: iTunesKind];
		MMPlaylist *playlist = [MMGenericPlaylist playlistWithKind:contentKind andSize:0];
		playlist.name = iTunesPlaylist.name;
		playlist.uniqueId = iTunesPlaylist.persistentID;
		
		[playlists addObject: playlist];
	}
	return playlists;
}

- (MMPlaylist*) createMediaLibrary: (iTunesPlaylist*) playlist
{
	
	SBElementArray *tracks = [playlist tracks];
	ITSiTunesWrapper *wrapper = [ITSiTunesWrapper wrapperWithArray: tracks];
	NSUInteger count = [wrapper count];
	
	MMContentKind contentKind = [self contentKindFromiTunesSpecialKind: playlist.specialKind];
	MMPlaylist *library = [MMGenericPlaylist playlistWithKind: contentKind andSize: count];
	
	for(int i = 0; i < count; i++)
	{
		MMContent *content = [MMContent content: contentKind];
		content.contentId = [wrapper idForIndex:i];
		content.name = [wrapper nameForIndex:i];
		content.genre = [wrapper genreForIndex:i];
		content.description = [wrapper descriptionForIndex:i];
		content.show = [wrapper showForIndex:i];
		content.season = [wrapper seasonForIndex:i];
		content.episodeNumber = [wrapper episodeForIndex:i];
		content.duration = [wrapper durationForIndex: i];
		content.unplayed = [wrapper unplayedForIndex: i];
		[library addContent: content];
	}
	return library;
}


#pragma mark - Enum converter
- (MMContentKind) contentKindFromiTunesSpecialKind: (iTunesESpK) specialKind
{
	MMContentKind kind;
	switch(specialKind) {
			
		case iTunesESpKMovies:
			kind = MOVIE;
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

- (iTunesEVdK) videoKindFromContentKind: (MMContentKind) kind
{
	iTunesEVdK specialKind;
	switch(kind) {
			
		case MOVIE:
			specialKind = iTunesEVdKMovie;
			break;
		case TV_SHOW:
			specialKind = iTunesEVdKTVShow;
			break;
		default:
			specialKind = -1;
			break;
	}
	return specialKind;
}


@end
