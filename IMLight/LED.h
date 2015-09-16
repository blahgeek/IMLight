//
//  LED.h
//  IMMonitor
//
//  Created by BlahGeek on 14/11/6.
//  Copyright (c) 2014年 BlahGeek. All rights reserved.
//

#ifndef IMMonitor_LED_h
#define IMMonitor_LED_h

#import <Cocoa/Cocoa.h>
#include <IOKit/IOCFPlugIn.h>
#include <IOKit/hid/IOHIDLib.h>

#define MAX_DEVICE_COUNT 16

@interface LED : NSObject
{
    IOHIDDeviceRef  ledDevices[MAX_DEVICE_COUNT];
    IOHIDElementRef ledElements[MAX_DEVICE_COUNT];
    int device_count;
}
// Pass either kHIDUsage_LED_NumLock or kHIDUsage_LED_CapsLock
-(id)initWithUsage:(uint32_t)usage;
-(void)setValue:(SInt32)value;
@end

#endif
