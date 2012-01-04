//
//  FRAvailability.h
//  RedFoundation
//
//  Created by Whitney Young on 5/2/11.
//  Copyright 2012 FadingRed LLC. All rights reserved.
//

#ifdef __APPLE__
#include <AvailabilityMacros.h>
#include <TargetConditionals.h>
#endif

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#define RED_TARGET_IOS 1
#elif TARGET_OS_MAC
#define RED_TARGET_MAC 1
#else
#error unknown os target
#endif
