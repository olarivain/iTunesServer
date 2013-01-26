//
//  MMTrackResource.m
//  CLIServer
//
//  Created by Kra on 5/30/11.
//  Copyright 2011 kra. All rights reserved.
//


#import <YARES/HSResourceDescriptor.h>
#import <YARES/HSResponse.h>
#import <YARES/HSHandlerPath.h>
#import <YARES/HSRequestParameters.h>
#import <MediaManagement/MMContent.h>

#import "ITSTrackResource.h"
#import "ITSiTunesContentRepository.h"
#import "MMContentAssembler+iTunes.h"

@implementation ITSTrackResource

#pragma mark - Rest Resource descriptor
- (NSArray*) resourceDescriptors
{
	HSResourceDescriptor *trackDescriptor = [HSResourceDescriptor descriptorWithPath: @"/library/{playlistId}/{trackId}" resource:self selector:@selector(updateTrack:) andMethod: POST];
	HSResourceDescriptor *tracksDescriptor = [HSResourceDescriptor descriptorWithPath: @"/library/{playlistId}" resource:self selector:@selector(updateTracks:) andMethod: POST];
	
	return [NSArray arrayWithObjects: trackDescriptor, tracksDescriptor, nil];
}

#pragma mark - Rest resource processing
- (HSResponse*) updateTracks: (HSRequestParameters*) params
{
	HSResponse *response = [HSResponse jsonResponse];
	
	MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
	
	NSArray *dtos = params.parameters;
	NSArray *tracks = [assembler createContentArray: dtos];
	[repository updateContents: tracks];
	
	return response;
}

- (HSResponse*) updateTrack: (HSRequestParameters*) params
{
	HSResponse *response = [HSResponse jsonResponse];
	
	MMContentAssembler *assembler = [MMContentAssembler sharedInstance];
	
	NSDictionary *dto = params.parameters;
	NSString *playlistId = [params.pathParameters nullSafeForKey: @"playlistId"];
	MMContent *track = [assembler createContent: dto];
	
	DDLogVerbose(@"Updating track %@", track.name);
	
	NSArray *tracks = [NSArray arrayWithObject: track];
	[repository updateContents: tracks];
	
	return response;
}

@end
