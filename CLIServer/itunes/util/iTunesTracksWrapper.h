//
//  iTunesTrackWrapper.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface iTunesTracksWrapper : NSObject {
  NSArray *ids;
  NSArray *names;
  NSArray *genres;
  NSArray *albums;
  NSArray *artists;
  NSArray *trackNumbers;
  NSArray *descriptions;
  NSArray *shows;
  NSArray *seasons;
  NSArray *episodes;

}

@property (nonatomic, readwrite, retain) NSArray *ids;
@property (nonatomic, readwrite, retain) NSArray *names;
@property (nonatomic, readwrite, retain) NSArray *genres;
@property (nonatomic, readwrite, retain) NSArray *albums;
@property (nonatomic, readwrite, retain) NSArray *artists;
@property (nonatomic, readwrite, retain) NSArray *trackNumbers;
@property (nonatomic, readwrite, retain) NSArray *descriptions;
@property (nonatomic, readwrite, retain) NSArray *shows;
@property (nonatomic, readwrite, retain) NSArray *seasons;
@property (nonatomic, readwrite, retain) NSArray *episodes;

+ (id) wrapper;

- (NSUInteger) count;

- (NSString *) idForIndex: (NSUInteger) index;
- (NSString *) nameForIndex: (NSUInteger) index;
- (NSString *) genreForIndex: (NSUInteger) index;
- (NSString *) albumForIndex: (NSUInteger) index;
- (NSString *) artistForIndex: (NSUInteger) index;
- (NSNumber *) trackNumberForIndex: (NSUInteger) index;
- (NSString *) descriptionForIndex: (NSUInteger) index;
- (NSString *) showForIndex: (NSUInteger) index;
- (NSNumber *) seasonForIndex: (NSUInteger) index;
- (NSNumber *) episodeForIndex: (NSUInteger) index;

@end
