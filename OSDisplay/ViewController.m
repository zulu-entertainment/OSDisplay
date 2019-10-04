//
//  ViewController.m
//  OSDisplay
//
//  Created by Marc on 17.01.16.
//  Copyright © 2016 Marc Wernecke. All rights reserved.
//

#import "ViewController.h"

#include <Foundation/Foundation.h>
#import <DiscRecording/DiscRecording.h>

BOOL darkMode;

@implementation OsdController
{
    NSTimer *exitTimer;
    NSColor *tintColor;
    BOOL showMessage;
    BOOL showImage;
    BOOL showLevel;
    float exitDelay;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    NSString *osdMessage = @"";
    NSString *osdLevelString = @"";
    NSString *osdImagePath = @"";
    NSInteger osdLevel = -1;
    NSInteger argc = [args count];
    NSString *tray = @"";
    exitDelay = 1.5;
    
    // Commandline arguments
    for (int i=1; i<argc; i++)
    {
        if ([args[i] isEqualToString:@"-m"]) {
            i++;
            if (i >= argc) break;
            osdMessage = args[i];
            if (osdMessage != nil) {
                showMessage = YES;
            } else {
                osdMessage = @"";
                showMessage = NO;
            }
        }
        
        else if ([args[i] isEqualToString:@"-l"]) {
            i++;
            if (i >= argc) break;
            osdLevelString = args[i];
            osdLevel = -1;
            showLevel = NO;
            if (osdLevelString != nil) {
                osdLevel = [osdLevelString integerValue];
                if (osdLevel >= 0 && osdLevel <= 100) {
                    showLevel = YES;
                    showMessage = NO;
                }
            }
        }
        
        else if ([args[i] isEqualToString:@"-i"]) {
            i++;
            if (i >= argc) break;
            osdImagePath = args[i];
            if (osdImagePath != nil) {
                showImage = YES;
            } else {
                osdImagePath = @"";
                showImage = NO;
            }
        }
        
        else if ([args[i] isEqualToString:@"-d"]) {
            i++;
            if (i >= argc) break;
            exitDelay = [args[i] floatValue];
            if (exitDelay < 0.1 || exitDelay > 60.0) {
                exitDelay = 1.5;
                ErrorLog(@"Resetting delay to: %f", exitDelay);
            }
        }
        
        else if ([args[i] isEqualToString:@"-t"] || [args[i] isEqualToString:@"-tray"]) {
            tray = @"auto";
            i++;
            if (i >= argc) break;
            tray = args[i];
        }
/*
        else if ([args[i] isEqualToString:@"-darkMode"]) {
            darkMode = YES;
        }
        
        else if ([args[i] isEqualToString:@"-lightMode"]) {
            darkMode = NO;
        }
*/        
        else if ([args[i] isEqualToString:@"-h"]) {
            HelpLog(@"-------------------------------------");
            HelpLog(@"%@ %@",
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
            HelpLog(@"-------------------------------------");
            HelpLog(@"Arguments:");
            HelpLog(@"  -i\tpath to image-file");
            HelpLog(@"  -m\tmessage (string)");
            HelpLog(@"  -l\tvalue (0-100)");
            HelpLog(@"  -d\tdelay (1.0-60.0 seconds)");
            HelpLog(@"  -t\tauto|open|close|eject (external cd/dvd writer)");
            HelpLog(@"  -h\t(show this help text)");
            HelpLog(@"-------------------------------------");
            HelpLog(@"Images become resized (max x150)");
            HelpLog(@"and tinted to support the activated");
            HelpLog(@"color-mode (light or dark).");
            HelpLog(@"\n");
            HelpLog(@"Supported formats are:");
            HelpLog(@"  .png");
            HelpLog(@"  .pdf");
            HelpLog(@"  .tiff");
            HelpLog(@"\n");
            HelpLog(@"Built-In images can be used with:");
            HelpLog(@"  -i brightness");
            HelpLog(@"  -i contrast");
            HelpLog(@"  -i eject");
            HelpLog(@"  -i monitor");
            HelpLog(@"  -i information");
            HelpLog(@"  -i monster");
            HelpLog(@"-------------------------------------");
            HelpLog(@"\n");
            
            osdMessage = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            osdImagePath = @"monster";
            showMessage = YES;
            showImage = YES;
            showLevel = NO;
        }
        
        else {
            ErrorLog(@"Unknown argument: %@", args[i]);
        }
    }
    
    DebugLog(@"Using arguments: -m '%@' -l '%@' -i '%@' -d '%f'", osdMessage, osdLevelString, osdImagePath, exitDelay);
    
    NSNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] count] > 1) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: osdImagePath, @"image", osdMessage, @"message", osdLevelString, @"level", nil];
        [center postNotificationName:@"de.zulu-entertainment.OSDisplay.LaunchCall" object:nil userInfo:info];
        DebugLog(@"Found another instance running - terminate now!");
        [NSApp terminate:nil];
    }
    else {
        [center addObserver:self selector:@selector(receiveNotification:) name:@"de.zulu-entertainment.OSDisplay.LaunchCall" object:nil];
        DebugLog(@"Starting first instance run");

        if (darkMode) {
            tintColor = [NSColor colorWithWhite:0.9 alpha:0.85];
        }
        else {
            tintColor = [NSColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
        }
        
        // configure the font size and color
        self.OsdTextField.font = [NSFont systemFontOfSize:18.0 weight:0.36];
        self.OsdTextField.textColor = tintColor;
        
        if (showMessage || showLevel) {
            self.imageTopSpace.constant = 10.0;
        } else {
            self.imageTopSpace.constant = (self.view.bounds.size.height-self.OsdImageView.bounds.size.height)/2;
        }

        if (showImage) {
            NSImage *osdImage = nil;
            self.textBottomSpace.constant = 10.0;
            
            if ([self haveInternalImage:osdImagePath]) {
                osdImage = [[NSImage imageNamed:osdImagePath] tintImageWithColor:tintColor];
            } else {
                if ([[NSFileManager defaultManager] fileExistsAtPath:osdImagePath]) {
                    osdImage = [[[NSImage alloc] initByReferencingFile:osdImagePath] tintImageWithColor:tintColor];
                    DebugLog(@"Found external image '%@'", osdImagePath);
                } else {
                    osdImage = [[NSImage imageNamed:@"information"] tintImageWithColor:tintColor];
                    osdMessage = @"Image not found!";
                    self.imageTopSpace.constant = 10.0;
                    showLevel = NO;
                    showMessage = YES;
                    ErrorLog(@"Error - image not found: '%@'", osdImagePath);
                }
            }
            self.OsdImageView.image = osdImage;
            
        } else if (showMessage) {
            self.OsdImageView.image = nil;
            self.textBottomSpace.constant = (self.view.bounds.size.height-self.OsdTextField.bounds.size.height)/2;
        } else {
            // tint and use the default image
            self.OsdImageView.image = [[NSImage imageNamed:@"monster"] tintImageWithColor:tintColor];
        }

        self.OsdLevelIndicator.hidden = YES;
        if (showMessage) {
            self.OsdTextField.hidden = NO;
        }
        
        if (showLevel) {
            self.OsdLevelIndicator.hidden = NO;
            self.OsdTextField.hidden = YES;
            self.OsdLevelIndicator.floatValue = osdLevel;
        }
        
        // show the message in any way
        self.OsdTextField.stringValue = osdMessage;

        if (tray != nil && ![tray isEqualToString:@""]) {
            dispatch_queue_t taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(taskQueue, ^{
                @try {
                    //DebugLog(@"Scanning for optical devices... '%@'", [DRDevice devices] );
                    if ([[DRDevice devices] count] > 0) {
                        DRDevice *device = [DRDevice devices][0];
                        DebugLog(@"Found: '%@'", [device displayName]);
                        if ([tray isEqualToString:@"auto"]) {
                            NSDictionary *deviceStatus = [device status];
                            //BOOL deviceIsBusy = [[deviceStatus objectForKey:DRDeviceIsBusyKey] boolValue];
                            BOOL deviceIsOpen = [[deviceStatus objectForKey:DRDeviceIsTrayOpenKey] boolValue];
                            if (deviceIsOpen) {
                                DebugLog(@"Tray is open, sending close...");
                                [device closeTray];
                            } else {
                                DebugLog(@"Tray is closed, sending eject...");
                                [device ejectMedia];
                            }
                        } else if ([tray isEqualToString:@"close"]) {
                            DebugLog(@"Sending close...");
                            [device closeTray];
                        } else if ([tray isEqualToString:@"open"]) {
                            DebugLog(@"Sending open...");
                            [device openTray];
                        } else if ([tray isEqualToString:@"eject"]) {
                            DebugLog(@"Sending eject...");
                            [device ejectMedia];
                        } else {
                            ErrorLog(@"Not supported argument: %@", tray);
                            ErrorLog(@"-tray auto");
                            ErrorLog(@"-tray open");
                            ErrorLog(@"-tray close");
                            ErrorLog(@"-tray eject");
                        }
                    } else {
                        ErrorLog(@"No optical devices!");
                        self.imageTopSpace.constant = 10.0;
                        self.OsdTextField.stringValue = @"No Drive!";
                    }
                }

                @catch (NSException *exception) {
                    NSLog(@"Problems running the task: %@", [exception description]);
                }

                @finally {

                }
            });

        }
        
        [self createExitTimer];
    }
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

- (void)createExitTimer
{
    exitTimer = [NSTimer scheduledTimerWithTimeInterval: exitDelay
                                                 target: self
                                               selector: @selector(timeout)
                                               userInfo: nil
                                                repeats: NO];
}

- (void)timeout
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        DebugLog(@"So long, ...");
        context.duration = 1.0f;
        self.view.window.animator.alphaValue = 0.0f;
    } completionHandler:^{
        DebugLog(@"and thanks for all the fish!");
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
        [NSApp terminate:self];
    }];
}


- (void)receiveNotification:(NSNotification *)notification
{
    DebugLog(@"Receive notification: '%@'\n %@ %@ %@",
             [notification name],
             [notification userInfo][@"image"],
             [notification userInfo][@"message"],
             [notification userInfo][@"level"]);
    
    if ([[notification name] isEqualToString:@"de.zulu-entertainment.OSDisplay.LaunchCall"])
    {
        [exitTimer invalidate];
        
        NSString *osdImagePath = [notification userInfo][@"image"];
        if (osdImagePath != nil) {
            showImage = YES;
            if ([osdImagePath isEqualToString:@""]) {
                showImage = NO;
            }
        } else {
            osdImagePath = @"";
            showImage = NO;
        }

        NSString *osdMessage = [notification userInfo][@"message"];
        if (osdMessage != nil) {
            showMessage = YES;
            if ([osdMessage isEqualToString:@""]) {
                showMessage = NO;
            }
        } else {
            osdMessage = @"";
            showMessage = NO;
        }
        
        NSString *osdLevelString = [notification userInfo][@"level"];
        float osdLevel = -1.0;
        showLevel = NO;
        if (osdLevelString != nil) {
            osdLevel = [osdLevelString integerValue];
            if (osdLevel >= 0 && osdLevel <= 100) {
                showLevel = YES;
                showMessage = NO;
            }
        }
        
        // image position
        if (showMessage || showLevel) {
            self.imageTopSpace.constant = 10.0;
        } else {
            self.imageTopSpace.constant = (self.view.bounds.size.height-self.OsdImageView.bounds.size.height)/2;
        }
        
        if (showImage) {
            NSImage *osdImage = nil;
            self.textBottomSpace.constant = 10.0;
            
            if ([self haveInternalImage:osdImagePath]) {
                osdImage = [[NSImage imageNamed:osdImagePath] tintImageWithColor:tintColor];
            } else {
                if ([[NSFileManager defaultManager] fileExistsAtPath:osdImagePath]) {
                    DebugLog(@"Found external image '%@'", osdImagePath);
                    osdImage = [[[NSImage alloc] initByReferencingFile:osdImagePath] tintImageWithColor:tintColor];
                } else {
                    osdImage = [[NSImage imageNamed:@"information"] tintImageWithColor:tintColor];
                    osdMessage = @"Image not found!";
                    self.imageTopSpace.constant = 10;
                    showLevel = NO;
                    showMessage = YES;
                }
            }
            self.OsdImageView.image = osdImage;
            
        } else if (showMessage) {
            self.OsdImageView.image = nil;
            self.textBottomSpace.constant = (self.view.bounds.size.height-self.OsdTextField.bounds.size.height)/2;
        }
        
        if (showMessage) {
            self.OsdLevelIndicator.hidden = YES;
            self.OsdTextField.hidden = NO;
        }
        self.OsdTextField.stringValue = osdMessage;
        
        if (showLevel) {
            self.OsdLevelIndicator.hidden = NO;
            self.OsdTextField.hidden = YES;
            self.OsdLevelIndicator.floatValue = osdLevel;
        }
        
        // create a new exit timer
        [self createExitTimer];
    }
}

- (BOOL)haveInternalImage:(NSString *)name
{
    if ([name isEqualToString:@"brightness"]) {
        return true;
    } else if ([name isEqualToString:@"contrast"]) {
        return true;
    } else if ([name isEqualToString:@"eject"]) {
        return true;
    } else if ([name isEqualToString:@"information"]) {
        return true;
    } else if ([name isEqualToString:@"monitor"]) {
        return true;
    } else if ([name isEqualToString:@"monster"]) {
        return true;
    }
    return false;
}

- (void)dealloc
{
    DebugLog(@"App dealloc");
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation OsdWindow

//- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
// SDK macOS 10.12+ -> NSWindowStyleMask
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
    if (self = [super initWithContentRect:contentRect
                                styleMask:NSBorderlessWindowMask
                                  backing:NSBackingStoreBuffered defer:deferCreation]) {
        [self setTitle:@"OSDisplay"];
        [self setOpaque:NO];
        [self setHasShadow:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setExcludedFromWindowsMenu:YES];
        [self setLevel:NSScreenSaverWindowLevel + 1];
        DebugLog(@"Init osd window");
    }
    return self;
}

@end


@implementation OsdView

-(id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    
    if (self) {
        
        NSOperatingSystemVersion os = [[NSProcessInfo processInfo] operatingSystemVersion];
        DebugLog(@"Found macOS %@", [NSString stringWithFormat:@"%ld.%ld.%ld", os.majorVersion, os.minorVersion, os.patchVersion]);
        DebugLog(@"Init visual effect view");
        
        self.wantsLayer = YES;
        self.layer.frame = self.bounds;
        self.layer.masksToBounds = YES;
        
        [self setBlendingMode:NSVisualEffectBlendingModeWithinWindow];
        [self setState:NSVisualEffectStateActive];
        [self setMaskImage:[[NSImage alloc] cornerMask]];
        
        /*  Material modes:
         
         macOS 10.11–10.14
         NSVisualEffectMaterialAppearanceBased       = 0 (deprecated)
         NSVisualEffectMaterialLight                 = 1 (deprecated)
         NSVisualEffectMaterialDark                  = 2 (deprecated)
         NSVisualEffectMaterialTitlebar              = 3
         NSVisualEffectMaterialSelection             = 4
         NSVisualEffectMaterialMenu                  = 5
         NSVisualEffectMaterialPopover               = 6
         sNSVisualEffectMaterialSidebar              = 7
         NSVisualEffectMaterialMediumLight           = 8 (deprecated)
         NSVisualEffectMaterialUltraDark             = 9 (deprecated)
         
         macOS 10.14+
         NSVisualEffectMaterialHeaderView            = 10
         NSVisualEffectMaterialSheet                 = 11
         NSVisualEffectMaterialWindowBackground      = 12
         NSVisualEffectMaterialHUDWindow             = 13
         NSVisualEffectMaterialFullScreenUI          = 15
         NSVisualEffectMaterialToolTip               = 17
         NSVisualEffectMaterialContentBackground     = 18
         NSVisualEffectMaterialUnderWindowBackground = 21
         NSVisualEffectMaterialUnderPageBackground   = 22
         ???                                         = 23
         ???                                         = 24
         ???                                         = 25
         ???                                         = 26
         ???                                         = 27
         ???                                         = 28
         
         */
        
        if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"]) {
            darkMode = YES;
            [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark]];
            if (os.majorVersion >= 10 && os.minorVersion >= 14) {
                [self setMaterial:27];
            } else {
                [self setMaterial:NSVisualEffectMaterialDark];
            }
        } else {
            darkMode = NO;
            [self setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameVibrantLight]];
            if (os.majorVersion >= 10 && os.minorVersion >= 14) {
                [self setMaterial:27];
            } else {
                [self setMaterial:NSVisualEffectMaterialLight];
            }
        }
        
        DebugLog(@"Using appearance: '%@' with material: '%i'", self.appearance.name, (int)[self material]);
    }
    return self;
}

-(BOOL)allowsVibrancy
{
    return true;
}

@end


@implementation OsdLevelIndicatorCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    // Defaults
    self.maxValue = 100;
    self.minValue = 0;
    NSColor *fillColor = [NSColor colorWithDeviceWhite:0.9 alpha:0.85];
    NSColor *backColor = [NSColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
    
    // Draw the background
    [backColor set];
    NSRectFill(NSInsetRect(cellFrame, 0, 5));
    cellFrame = NSInsetRect(cellFrame, 0.9, 6);
    
    // Draw the segments
    [fillColor set];
    double val = ((self.floatValue - self.minValue) / (self.maxValue - self.minValue) * (self.maxValue - self.minValue) / 100);
    int segments = (int)(self.maxValue - self.minValue);
    float segment = cellFrame.size.width / segments;
    int ifill = val * segments + 0.5;
    
    for (int i=0; i<segments; i++) {
        NSRect seg = cellFrame;
        if (i < ifill) {
            if (i % 5) {
                seg.size.width = segment+0.5;
                seg.origin.x  += i*segment-0.5;
            }
            else {
                seg.size.width = segment-1.0;
                seg.origin.x  += i*segment;
            }
            NSRectFill(seg);
        } else {
            return;
        }
    }
}

@end


@implementation NSImage (osd)

/* 
 Create a drawing mask for the visual effect view
 */
- (NSImage *)_cornerMask
{
    CGFloat radius = 18.0;
    CGFloat dimension = 2 * radius + 1;
    NSSize size = NSMakeSize(dimension, dimension);
    NSImage *image = [NSImage imageWithSize:size flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
        NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:dstRect xRadius:radius yRadius:radius];
        [[NSColor blackColor] set];
        [bezierPath setLineJoinStyle:NSRoundLineJoinStyle];
        [bezierPath fill];
        return YES;
    }];
    image.capInsets = NSEdgeInsetsMake(radius, radius, radius, radius);
    image.resizingMode = NSImageResizingModeStretch;
    return image;
}

- (NSImage *)cornerMask
{
    return [self _cornerMask];
}

/*
 Tint the image with a given color
 */
- (NSImage *)_tintImageWithColor:(NSColor *)color
{
    NSImage *image = [self copy];
    if (color) {
        [image lockFocus];
        [color set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositeSourceIn);
        [image unlockFocus];
    }
    return image;
}

- (NSImage *)tintImageWithColor:(NSColor *)color
{
    return [self _tintImageWithColor:(NSColor *)color];
}

@end
