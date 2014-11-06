//
//  AppDelegate.m
//  IMLight
//
//  Created by BlahGeek on 14/11/6.
//  Copyright (c) 2014年 BlahGeek. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.launchController = [[LaunchAtLoginController alloc] init];
    [self.startAtLoginItem setState:([self.launchController launchAtLogin] ? NSOnState : NSOffState)];
    
    self.caps_led = [[LED alloc] initWithUsage:kHIDUsage_LED_CapsLock];
    [[NSDistributedNotificationCenter defaultCenter]
     addObserverForName:(__bridge NSString *)kTISNotifySelectedKeyboardInputSourceChanged
     object:nil
     queue:nil
     usingBlock:^(NSNotification * noti) {
         
         CFArrayRef all_im = TISCreateInputSourceList(NULL, false);
         for(int i = 0 ; i < CFArrayGetCount(all_im) ; i += 1) {
             TISInputSourceRef im = (TISInputSourceRef)CFArrayGetValueAtIndex(all_im, i);
             
             CFStringRef im_type = TISGetInputSourceProperty(im, kTISPropertyInputSourceType);
             CFBooleanRef im_selected = TISGetInputSourceProperty(im, kTISPropertyInputSourceIsSelected);
             if (CFBooleanGetValue(im_selected) == YES) {
                 [self.caps_led setValue:(im_type != kTISTypeKeyboardLayout)];
                 break;
             }
         }
         CFRelease(all_im);
     }
    ];
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)awakeFromNib {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusBar setTitle:@"A"];
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

- (IBAction)setStartAtLogin:(id)sender {
    NSUInteger state = NSOffState;
    if(self.startAtLoginItem.state == NSOffState)
        state = NSOnState;
    [self.startAtLoginItem setState:state];
    [self.launchController setLaunchAtLogin: (state == NSOnState)];
}
@end
