//
//  iTunesTrackWrapper.m
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "iTunesWrapper.h"
#import <ScriptingBridge/ScriptingBridge.h>

@interface iTunesWrapper()
- (NSString *) string: (NSArray*) array forIndex: (NSUInteger) index;
- (NSNumber *) number: (NSArray*) array forIndex: (NSUInteger) index;
@end

@implementation iTunesWrapper

+ (id) wrapper
{
  return [[[iTunesWrapper alloc] init] autorelease];
}

+ (id) wrapperWithArray:(SBElementArray *)array 
{
  iTunesWrapper *wrapper = [iTunesWrapper wrapper];
  wrapper.ids = [array valueForKey:@"persistentID"];
  wrapper.names = [array valueForKey:@"name"];
  wrapper.genres =[array valueForKey:@"genre"];
  wrapper.albums = [array valueForKey:@"album"];
  wrapper.artists = [array valueForKey:@"artist"];
  wrapper.trackNumbers = [array valueForKey:@"trackNumber"];
  wrapper.descriptions = [array valueForKey:@"objectDescription"];
  wrapper.shows = [array valueForKey:@"show"];
  wrapper.episodes = [array valueForKey:@"episodeNumber"];
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

- (void)dealloc
{
  self.ids = nil;
  self.iTunesKinds = nil;
  self.names = nil;
  self.genres = nil;
  self.albums = nil;
  self.artists = nil;
  self.trackNumbers = nil;
  self.descriptions = nil;
  self.shows = nil;
  self.seasons = nil;
  self.episodes = nil;
  [super dealloc];
}

@synthesize ids;
@synthesize names;
@synthesize genres;
@synthesize albums;
@synthesize artists;
@synthesize trackNumbers;
@synthesize descriptions;
@synthesize shows;
@synthesize seasons;
@synthesize episodes;
@synthesize iTunesKinds;

#pragma mark - Count
- (NSUInteger) count 
{
  return [ids count];
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
  return [self number:self.seasons forIndex:index];
}

- (NSNumber *) episodeForIndex: (NSUInteger) index
{
  return [self number:self.episodes forIndex:index];
}

#pragma mark - private out of bounds safe accessors
- (NSString *) string: (NSArray*) array forIndex: (NSUInteger) index
{
  if(index < [array count])
  {
    return (NSString*) [array objectAtIndex: index];
  }
  return nil;
}
- (NSNumber *) number: (NSArray*) array forIndex: (NSUInteger) index
{
  if(index < [array count])
  {
    return (NSNumber*) [array objectAtIndex: index];
  }
  return nil;
}

@end
