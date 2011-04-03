//
//  Method.h
//  HTTPServe
//
//  Created by Kra on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef enum HttpMethod
{
  GET,
  PUT,
  POST,
  DELETE
} HttpMethod;


enum HttpMethod methodFromString(NSString *method);
NSString* stringFromMethod(HttpMethod method);