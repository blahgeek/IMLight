//
//  AppDelegate.h
//  IMLight
//
//  Created by BlahGeek on 14/11/6.
//  Copyright (c) 2014年 BlahGeek. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LED.h"
#import "LaunchAtLoginController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSMenu *statusMenu;
@property (weak) IBOutlet NSMenuItem *startAtLoginItem;
@property (strong, nonatomic) NSStatusItem *statusBar;

@property (strong) LED * caps_led;
@property (strong) LaunchAtLoginController * launchController;
- (IBAction)setStartAtLogin:(id)sender;

@end

