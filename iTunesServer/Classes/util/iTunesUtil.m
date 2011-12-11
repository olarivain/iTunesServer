//
//  iTunesUtil.m
//  CLIServer
//
//  Created by Kra on 5/2/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "iTunesUtil.h"


@implementation iTunesUtil

+ (NSString*) iTunesEnumToString: (unsigned int) iTunesEnum
{
  unsigned char first = (iTunesEnum & 0xFF000000) >> 24;
  unsigned char second = (iTunesEnum & 0x00FF0000) >> 16;
  unsigned char third = (iTunesEnum & 0x0000FF00) >> 8;
  unsigned char fourth = iTunesEnum & 0x000000FF;
  return [NSString stringWithFormat:@"'%c%c%c%c'", first, second, third, fourth];
}

@end
