//
//  ITSConfigurationRepository.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/10/11.
//  Copyright (c) 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ITSConfiguration;

@interface ITSConfigurationRepository : NSObject {
	ITSConfiguration *configuration;
}

+ (ITSConfigurationRepository *) sharedInstance;

- (ITSConfiguration *) readConfiguration;
- (ITSConfiguration *) saveConfiguration;
- (ITSConfiguration *) forceReload;

@end
