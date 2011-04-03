//
//  ScriptRepository.h
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

#define READ_SCRIPTS @"GetContent"
#define WRITE_SCRIPTS @"SetContent"

@interface ScriptRepository : NSObject {
@private
  NSMutableDictionary *scripts;
}

+ (id) sharedInstance;
- (NSAppleScript*) scriptForKey: (NSString*) key;

@end
