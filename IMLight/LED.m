//
//  LED.m
//  IMMonitor
//
//  Created by BlahGeek on 14/11/6.
//  Copyright (c) 2014年 BlahGeek. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach_error.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include "LED.h"

static NSMutableDictionary* _CreateMatchingDict(Boolean isDeviceNotElement,
                                                uint32_t inUsagePage,
                                                uint32_t inUsage);

static NSMutableDictionary* _CreateMatchingDict(Boolean isDeviceNotElement,
                                                uint32_t inUsagePage,
                                                uint32_t inUsage)
{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                [NSNumber numberWithUnsignedInt:inUsagePage],
                                (isDeviceNotElement)?
                                CFSTR(kIOHIDDeviceUsagePageKey):
                                CFSTR(kIOHIDElementUsagePageKey),
                                NULL];
    if (inUsage) [dic setObject:[NSNumber numberWithUnsignedInt:inUsage]
                         forKey:(isDeviceNotElement)?
                  (NSString*)CFSTR(kIOHIDDeviceUsageKey):
                  (NSString*)CFSTR(kIOHIDElementUsageKey)];
    return dic;
}

@implementation LED
-(id)init
{
    return [self initWithUsage:kHIDUsage_LED_CapsLock];
}

-(id)initWithUsage:(uint32_t)usage
{
    self = [super init];
    device_count = 0;
    
    CFSetRef deviceCFSetRef = NULL;
    IOHIDDeviceRef* refs = NULL;
    // create a IO HID Manager reference
    IOHIDManagerRef mgr = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if(!mgr)
        return self;
    // Create a device matching dictionary
    NSDictionary* dic = _CreateMatchingDict(true, kHIDPage_GenericDesktop,
                                            kHIDUsage_GD_Keyboard);
    require(dic, Oops);
    // set the HID device matching dictionary
    IOHIDManagerSetDeviceMatching(mgr, (__bridge CFDictionaryRef)dic);
//    [dic release];
    // Now open the IO HID Manager reference
    IOReturn err = IOHIDManagerOpen(mgr, kIOHIDOptionsTypeNone);
    require_noerr(err, Oops);
    // and copy out its devices
    deviceCFSetRef = IOHIDManagerCopyDevices(mgr);
    require(deviceCFSetRef, Oops);
    // how many devices in the set?
    CFIndex deviceIndex, deviceCount = CFSetGetCount(deviceCFSetRef);
    // allocate a block of memory to extact the device refs from the set into
    refs = malloc(sizeof(IOHIDDeviceRef) * deviceCount);
    require(refs, Oops);
    // now extract the device refs from the set
    CFSetGetValues(deviceCFSetRef, (const void**)refs);
    // before we get into the device loop set up element matching dictionary
    dic = _CreateMatchingDict(false, kHIDPage_LEDs, 0);
    require(dic, Oops);
    for (deviceIndex = 0; deviceIndex < deviceCount; deviceIndex++)
    {
        // if this isn't a keyboard device...
        if (!IOHIDDeviceConformsTo(refs[deviceIndex], kHIDPage_GenericDesktop,
                                   kHIDUsage_GD_Keyboard))
        {
            //printf("skipping nonconforming device at %d\n", deviceIndex);
            continue;  // ...skip it
        }
        // copy all the elements
        CFArrayRef elements = IOHIDDeviceCopyMatchingElements(refs[deviceIndex],
                                                              (__bridge CFDictionaryRef)dic,
                                                              kIOHIDOptionsTypeNone);
        if(!elements)
            continue;
        // iterate over all the elements
        CFIndex i, n = CFArrayGetCount(elements);
        for (i = 0; i < n; i++)
        {
            IOHIDElementRef element = (IOHIDElementRef)CFArrayGetValueAtIndex(elements, i);
            if(!element)
                continue;
            uint32_t usagePage = IOHIDElementGetUsagePage(element);
            // if this isn't an LED element, skip it
            if (kHIDPage_LEDs != usagePage) continue;
            uint32_t elusage = IOHIDElementGetUsage(element);
            if (elusage == usage)
            {
                ledDevices[device_count] = (IOHIDDeviceRef)CFRetain(refs[deviceIndex]);
                ledElements[device_count++] = (IOHIDElementRef)CFRetain(element);
                break;
            }
        next_element:  ;
            continue;
        }
    next_device: ;
        if (elements) CFRelease(elements);
        continue;
    }
    if (mgr) CFRelease(mgr);
//    [dic release];
Oops:  ;
    if (deviceCFSetRef) CFRelease(deviceCFSetRef);
    if (refs) free(refs);
    
    NSLog(@"LED Inited, %d devices found", device_count);
    return self;
}

-(void)dealloc
{
    for(int i = 0 ; i < device_count ; i += 1) {
        
        if (ledDevices[i]) CFRelease(ledDevices[i]);
        if (ledElements[i]) CFRelease(ledElements[i]);
    }
//    [super dealloc];
}

-(void)setValue:(SInt32)value
{
    for(int i = 0 ; i < device_count ; i += 1) {
        if (ledDevices[i] && ledElements[i])
        {
            IOReturn err = IOHIDDeviceOpen(ledDevices[i], 0);
            if (!err)
            {
                // create the IO HID Value to be sent to this LED element
                uint64_t timestamp = 0;
                IOHIDValueRef val = IOHIDValueCreateWithIntegerValue(kCFAllocatorDefault,
                                                                     ledElements[i], timestamp,
                                                                     value);
                if (val)
                {
                    // now set it on the device
                    err = IOHIDDeviceSetValue(ledDevices[i], ledElements[i], val);
                    CFRelease(val);
                }
                IOHIDDeviceClose(ledDevices[i], 0);
            }
            if (err) printf("error 0x%X\n", err);
        }
    }

}
@end