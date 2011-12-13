//
//  ITSDefaults.h
//  iTunesServer
//
//  Created by Larivain, Olivier on 12/11/11.
//  Copyright (c) 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AUTO_IMPORT_KEY @"autoScanEnabled"
#define AUTO_IMPORT_PATH_KEY @"autoScanPath"
#define ITUNES_SERVER_PORT_KEY @"port"
#define START_ON_LOGIN_KEY @"starOnLogin"


@interface ITSDefaults : NSObject

+ (void) bootstrapDefaults: (NSUserDefaults *) defaults;

@end
