//
//  main.m
//  CLIServer
//
//  Created by Kra on 3/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServe/HSHTTPServe.h>

int main (int argc, const char * argv[])
{
  @autoreleasepool {
    HSHTTPServe *server = [[HSHTTPServe alloc] initWithPort: 2048];
    [server start];
    [[NSRunLoop currentRunLoop] run]; // this will not return
    [server stop];
  }
  exit(0);
}

