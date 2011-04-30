//
//  ScriptRepository.m
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import "ScriptRepository.h"

static ScriptRepository *sharedInstance;

@interface ScriptRepository(private)
- (NSString *) pathForKey: (NSString*) key andPrefix: (NSString*) prefix;
- (NSString*) globalPathForKey: (NSString*) key;
- (NSString*) userPathForKey: (NSString*) key;
- (BOOL) scriptExists: (NSString*) path;
@end

@implementation ScriptRepository

+ (id) sharedInstance {
  @synchronized(self) {
    if(sharedInstance == nil){
      sharedInstance = [[ScriptRepository alloc] init];
    }
  }
  return sharedInstance;
}

- (id)init
{
  self = [super init];
  if (self) {
    scripts = [[NSMutableDictionary alloc] init];
  }
    
  return self;
}

- (void)dealloc
{
  [scripts dealloc];
  [super dealloc];
}

#pragma mark - Convenience private methods
- (NSString *) pathForKey: (NSString*) key andPrefix: (NSString*) prefix 
{
  return [NSString stringWithFormat:@"%@/%@.app", prefix, key];
}

- (NSString*) globalPathForKey: (NSString*) key 
{
  return [self pathForKey:key andPrefix:@"/Library/Application Support/kra/iTunes Server"];
}

- (NSString*) userPathForKey: (NSString*) key
{
  return [self pathForKey:key andPrefix:@"~/Library/Application Support/kra/iTunes Server"];

}

- (BOOL) scriptExists: (NSString*) path
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath: path];
}

#pragma mark - Repository methods
- (NSAppleScript*) scriptForKey:(NSString *)key 
{
  // check if script has already been instantiated
  @synchronized(self) {
    NSAppleScript *script = [scripts objectForKey: key];
//    if(script == nil){
  
      // no match, figure out script path
      NSString *path = [self globalPathForKey: key];
      if(![self scriptExists: path])
      {
        path = [self userPathForKey: key];
        if(![self scriptExists: path]){
          return nil;
        }
      }
      
      // instantiate it
      NSDictionary *error = nil;
      NSURL *scriptURL = [NSURL fileURLWithPath:path];
      script = [[[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&error] autorelease];
      
      // couldn't load script, log and exit
      if([error count])
      {
        NSLog(@"Error happened loading script with key %@: %@", key, error);
        return nil;
      }
      
      // cache and return
//      [scripts setObject:script forKey:key];
      
      if(![script isCompiled])
      {
        NSDictionary *errors = nil;
        [script compileAndReturnError: &errors];
      }
//    }
    return script;
  }
}

@end
