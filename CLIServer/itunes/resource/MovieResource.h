//
//  PhonyResource.h
//  CLIServer
//
//  Created by Kra on 3/12/11.
//  Copyright 2011 kra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <HTTPServe/HSRestResource.h>

#import "AbstractContentResource.h"

@interface MovieResource : AbstractContentResource<HSRestResource> 
{
}

@end
