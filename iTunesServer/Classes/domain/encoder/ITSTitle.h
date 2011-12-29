//
//  ITSEncodableContent.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/26/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ITSTitle : NSObject
{
  NSInteger index;
  NSInteger chapterCount;
  NSString *name;
  NSArray *soundTracks;
  NSArray *subtitleTrack;
  NSTimeInterval duration;
}

@end
