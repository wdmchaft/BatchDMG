/* This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface Imager : NSObject
{
  BOOL g_observing;         // a flag to let us know if we're imaging
  NSString *destination;    // destination folder
  NSMutableArray *sources;  // list of volumes being imaged
}

- (void)observeWorkspace: (NSNotification*) notification;
- (void)checkTaskStatus: (NSNotification*) notification;
- (id)initWithPath: (NSString*) path;

@end

@implementation Imager

- (id) initWithPath:(NSString*) path
{
    [super init];
    
    id fm = [NSFileManager defaultManager];
    
    // no output path given
    if (![fm fileExistsAtPath:path])
    {
        path = [fm currentDirectoryPath];
    }
    
    destination = path;
    
	// observer for disk mounts
    if (!g_observing)
    {
        NSLog(@"Waiting for media...");
        NSNotificationCenter* center;
	  
        center = [[NSWorkspace sharedWorkspace] notificationCenter];
        [center addObserver: self
                   selector: @selector(observeWorkspace:)
                       name: @"NSWorkspaceDidMountNotification"
                     object: nil];
	
        g_observing = YES;
        sources = [NSMutableArray arrayWithCapacity:99];
    }
    
	// observer for finished rips
	[[NSNotificationCenter defaultCenter] addObserver:self
			selector:@selector(checkTaskStatus:)
			name:NSTaskDidTerminateNotification
			object:nil];
	
  return self;
  
}

- (void)checkTaskStatus:(NSNotification *)aNotification
{
    int status = [[aNotification object] terminationStatus];
    NSLog(@"hdiutil completed with status %d", status);
    NSArray *args = [[aNotification object] arguments];
    
    if (status == 0)
    {
        if ([args count] > 4) // a ripping task
        {
            NSString *path = [args objectAtIndex:5];
            NSArray *eject = [NSArray arrayWithObjects:@"eject", @"-quiet", path, nil];
            [NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil" arguments:eject];
            [sources removeObjectIdenticalTo:[args objectAtIndex:6]];
		}
	}
}

- (void)observeWorkspace: (NSNotification*)notification
{
	id ui = [notification userInfo];
	NSString *path = [ui valueForKey:@"NSDevicePath"];
    NSString *volName = [ui valueForKey:@"NSWorkspaceVolumeLocalizedNameKey"];
    
    // disc is already being ripped
    if ([sources containsObject:volName]) {
        return;
    }
         
     NSLog(@"Imaging: %@", volName);
     
     NSTask *dmg = [[NSTask alloc] init];
     NSMutableArray *args = [NSMutableArray arrayWithObjects:@"create",
                             @"-ov",
                             @"-format",
                             @"UDBZ",
                             @"-srcfolder",
                             path,
                             volName,
                             nil];
     
     [sources addObject:volName];
     [dmg setCurrentDirectoryPath:[destination stringByStandardizingPath]];
     [dmg setLaunchPath:@"/usr/bin/hdiutil"];
     [dmg setArguments:args];
     [dmg launch];
         
}
         
- (void)dealloc
{
  if (g_observing)
  {
    NSNotificationCenter* center;
    
    // remove notifications within our app
    center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self];
    
    // remove notifications from NSWorkspace
    center = [[NSWorkspace sharedWorkspace] notificationCenter];
    [center removeObserver: self];
    
    // remove machine-wide notifications
    center = [NSDistributedNotificationCenter defaultCenter];
    [center removeObserver: self];
    
    g_observing = NO;
  }
  
  [super dealloc];
    
}

@end

int main(int argc, const char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *path = [NSString string];
    
    // output path given
    if (argc == 2)
    {
        path = [NSString stringWithCString:argv[1] encoding:NSUnicodeStringEncoding];
    }
    
    NSRunLoop *rl = [NSRunLoop currentRunLoop];
    
    [[Imager alloc] initWithPath:path];
    [rl run];
    [pool release];
    return 0;
}
