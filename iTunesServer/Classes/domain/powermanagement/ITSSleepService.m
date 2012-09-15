//
//  ITSSleepService.m
//  iTunesServer
//
//  Created by Olivier Larivain on 9/15/12.
//  Copyright (c) 2012 Edmunds. All rights reserved.
//

#import "ITSSleepService.h"

static ITSSleepService *sharedInstance;

@implementation ITSSleepService

+ (ITSSleepService *) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ITSSleepService alloc] init];
    });
    return sharedInstance;
}

- (void) enableSleep: (BOOL) allow {
    @synchronized(self) {
        // no change, just abort
        if(allow == sleepEnabled) {
            return;
        }
        
        sleepEnabled = allow;
    }
    
    if(sleepEnabled) {
        [self enableSleep];
    } else {
        [self preventSleep];
    }
}

- (void) preventSleep {
    IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep,
                                           kIOPMAssertionLevelOn, CFSTR("itsSleepAssertion"), &sleepAssertionID);
    if(success != 0) {
        NSLog(@"WARNING: Could not obtain sleep assertion, the host will probably go to sleep before jobs are completed.");
    }
}

- (void) enableSleep {
    IOReturn success = IOPMAssertionRelease(sleepAssertionID);
    
    if(success != 0) {
        NSLog(@"WARNING: Could not release sleep assertion, the host will not go to sleep anymore.");
    }
}

@end
