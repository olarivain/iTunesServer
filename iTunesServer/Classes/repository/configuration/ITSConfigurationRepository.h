//
//  ITSConfigurationRepository.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSConfiguration;

@interface ITSConfigurationRepository : NSObject {
  ITSConfiguration *configuration;
}
+ (ITSConfigurationRepository *) sharedInstance;
- (ITSConfiguration *) readConfiguration;
- (void) test;
@end
