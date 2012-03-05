//
//  MMTitle+MMTitle_Handbrake.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 1/3/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import <MediaManagement/MMTitle.h>

@interface MMTitle (MMTitle_Handbrake)

+ (MMTitle *) titleWithIndex:(NSInteger)index andHandbrakeDuration:(NSInteger)duration;

@end
