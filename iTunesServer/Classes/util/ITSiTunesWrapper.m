//
//  iTunesTrackWrapper.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ITSiTunesWrapper.h"
#import <ScriptingBridge/ScriptingBridge.h>

@interface ITSiTunesWrapper()
- (NSString *) string: (NSArray*) array forIndex: (NSUInteger) index;
- (NSNumber *) number: (NSArray*) array forIndex: (NSUInteger) index;
@end

@implementation ITSiTunesWrapper

+ (id) wrapper
{
	return [[ITSiTunesWrapper alloc] init];
}

+ (id) wrapperWithArray:(SBElementArray *)array
{
	ITSiTunesWrapper *wrapper = [ITSiTunesWrapper wrapper];
	wrapper.ids = [array valueForKey:@"persistentID"];
	wrapper.names = [array valueForKey:@"name"];
	wrapper.genres =[array valueForKey:@"genre"];
	wrapper.albums = [array valueForKey:@"album"];
	wrapper.artists = [array valueForKey:@"artist"];
	wrapper.trackNumbers = [array valueForKey:@"trackNumber"];
	wrapper.descriptions = [array valueForKey:@"objectDescription"];
	wrapper.shows = [array valueForKey:@"show"];
	wrapper.episodes = [array valueForKey:@"episodeNumber"];
	wrapper.seasons = [array valueForKey:@"seasonNumber"];
	wrapper.duration = [array valueForKey:@"duration"];
	wrapper.unplayed = [array valueForKey: @"unplayed"];
	return wrapper;
}

- (id)init
{
	self = [super init];
	if (self)
	{
	}
	
	return self;
}


#pragma mark - Count
- (NSUInteger) count
{
	return [self.ids count];
}

#pragma mark - out of bounds safe accessors
- (NSString *) idForIndex: (NSUInteger) index
{
	return [self string:self.ids forIndex:index];
}

- (NSNumber *) iTunesKindForIndex: (NSUInteger) index
{
	return [self number: self.iTunesKinds forIndex: index];
}

- (NSNumber *) durationForIndex: (NSUInteger) index
{
	return [self number: self.duration forIndex: index];
}

- (NSString *) nameForIndex: (NSUInteger) index
{
	return [self string:self.names forIndex:index];
}

- (NSString *) genreForIndex: (NSUInteger) index
{
	return [self string:self.genres forIndex:index];
}

- (NSString *) albumForIndex: (NSUInteger) index
{
	return [self string:self.albums forIndex:index];
}

- (NSString *) artistForIndex: (NSUInteger) index
{
	return [self string:self.artists forIndex:index];
}

- (NSNumber *) trackNumberForIndex: (NSUInteger) index
{
	return [self number:self.trackNumbers forIndex:index];
}

- (NSString *) descriptionForIndex: (NSUInteger) index
{
	return [self string:self.descriptions forIndex:index];
}

- (NSString *) showForIndex: (NSUInteger) index
{
	return [self string:self.shows forIndex:index];
}

- (NSNumber *) seasonForIndex: (NSUInteger) index
{
	return [self nonZeroNumber:self.seasons forIndex:index];
}

- (NSNumber *) episodeForIndex: (NSUInteger) index
{
	return [self nonZeroNumber:self.episodes forIndex:index];
}

- (BOOL) unplayedForIndex: (NSUInteger) index
{
	return [self number: self.unplayed forIndex: index].boolValue;
}

#pragma mark - private out of bounds safe accessors
- (NSString *) string: (NSArray*) array forIndex: (NSUInteger) index
{
	return (NSString*) [array boundSafeObjectAtIndex: index];
}
- (NSNumber *) number: (NSArray*) array forIndex: (NSUInteger) index
{
	return (NSNumber*) [array boundSafeObjectAtIndex: index];
}

- (NSNumber *) nonZeroNumber: (NSArray*) array forIndex: (NSUInteger) index
{
	NSNumber *number = (NSNumber*) [array boundSafeObjectAtIndex: index];
	return number.intValue == 0 ? nil : number;
}

@end
