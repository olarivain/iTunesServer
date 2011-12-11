//
//  iTunesTrackWrapper.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SBElementArray;

@interface iTunesWrapper : NSObject {
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
  NSArray *iTunesKinds;
}

@property (nonatomic, readwrite, strong) NSArray *ids;
@property (nonatomic, readwrite, strong) NSArray *iTunesKinds;
@property (nonatomic, readwrite, strong) NSArray *names;
@property (nonatomic, readwrite, strong) NSArray *genres;
@property (nonatomic, readwrite, strong) NSArray *albums;
@property (nonatomic, readwrite, strong) NSArray *artists;
@property (nonatomic, readwrite, strong) NSArray *trackNumbers;
@property (nonatomic, readwrite, strong) NSArray *descriptions;
@property (nonatomic, readwrite, strong) NSArray *shows;
@property (nonatomic, readwrite, strong) NSArray *seasons;
@property (nonatomic, readwrite, strong) NSArray *episodes;

+ (id) wrapper;
+ (id) wrapperWithArray: (SBElementArray*) array;

- (NSUInteger) count;

- (NSString *) idForIndex: (NSUInteger) index;
- (NSNumber *) iTunesKindForIndex: (NSUInteger) index;
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
