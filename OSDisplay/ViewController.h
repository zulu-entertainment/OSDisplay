//
//  ViewController.h
//  OSDisplay
//
//  Created by Marc on 17.01.16.
//  Copyright © 2016 Marc Wernecke. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef DEBUG
#   define DebugLog(...) NSLog(__VA_ARGS__)
#else
#   define DebugLog(...)
#endif

#define ErrorLog(...) NSLog(__VA_ARGS__)
#define HelpLog(...) NSLog(__VA_ARGS__)

@interface OsdController : NSViewController

@property (weak) IBOutlet NSTextField *OsdTextField;
@property (weak) IBOutlet NSImageView *OsdImageView;
@property (weak) IBOutlet NSLevelIndicator *OsdLevelIndicator;

@property (weak) IBOutlet NSLayoutConstraint *imageHeight;
@property (weak) IBOutlet NSLayoutConstraint *imageWidth;
@property (weak) IBOutlet NSLayoutConstraint *imageTopSpace;
@property (weak) IBOutlet NSLayoutConstraint *textBottomSpace;

@end

@interface OsdWindow : NSWindow
@end

@interface OsdView : NSVisualEffectView
@end

@interface OsdLevelIndicatorCell : NSLevelIndicatorCell
@end

@interface NSImage(osd)

- (NSImage *)cornerMask;
- (NSImage *)tintImageWithColor:(NSColor *)tint;

@end