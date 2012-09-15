//
//  ITSSleepService.h
//  iTunesServer
//
//  Created by Olivier Larivain on 9/15/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

@interface ITSSleepService : NSObject {
    BOOL sleepEnabled;
    IOPMAssertionID sleepAssertionID;
}

+ (ITSSleepService *) sharedInstance;

- (void) enableSleep: (BOOL) allow;

@end
