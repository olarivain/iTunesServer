//
//  main.m
//  CLIServer
//
//  Created by Kra on 3/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServe.h"
int main (int argc, const char * argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  HTTPServe *server = [[HTTPServe alloc] initWithPort: 2048];
  [server start];
  [[NSRunLoop currentRunLoop] run]; // this will not return
  [server stop];
  [server release];
  [pool release];
  exit(0);
}

