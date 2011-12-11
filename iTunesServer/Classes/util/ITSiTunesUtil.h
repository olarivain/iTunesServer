//
//  iTunesUtil.h
//  CLIServer
//
//  Created by Kra on 5/2/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

#define iTunesEnumToString(X) [iTunesUtil iTunesEnumToString: X]

@interface ITSiTunesUtil : NSObject 

+ (NSString*) iTunesEnumToString: (unsigned int) iTunesEnum;

@end
