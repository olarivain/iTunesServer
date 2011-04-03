//
//  RestResource.h
//  HTTPServe
//
//  Created by Kra on 2/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol RestResource <NSObject>

- (NSArray*) resourceDescriptors;

@optional
- (void) initialize;

@end
