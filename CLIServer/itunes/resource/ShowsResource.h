//
//  ShowsResource.h
//  CLIServer
//
//  Created by Kra on 5/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServe/HSRestResource.h>

#import "AbstractContentResource.h"

@interface ShowsResource :  AbstractContentResource<HSRestResource> 
{
}
@end