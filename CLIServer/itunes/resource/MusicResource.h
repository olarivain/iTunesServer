//
//  MusicResource.h
//  CLIServer
//
//  Created by Kra on 4/3/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServe/HSRestResource.h>

#import "AbstractContentResource.h"

@interface MusicResource : AbstractContentResource<HSRestResource> 
{
}

@end
