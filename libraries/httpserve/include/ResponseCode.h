//
//  ResponseCode.h
//  HTTPServe
//
//  Created by Kra on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
   OK = 200,
   CREATED = 201,
   NO_CONTENT = 204,
   MOVED_PERMANENTLY = 302,
   BAD_REQUEST = 400,
   FORBIDDEN = 403,
   NOT_FOUND = 404,
   INTERNAL_SERVER_ERROR = 500,
   UNAVAILABLE = 503,
} ResponseCode;