#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface Imager : NSObject
{
  BOOL g_observing;
  NSString *destination;
}

- (void)observeWorkspace: (NSNotification*) notification;
- (void)checkTaskStatus: (NSNotification*) notification;

@end

@implementation Imager

- (id) init
{
  [super init];
    
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
	NSLog(@"Task completed with status %d", status);
	id args = [[aNotification object] arguments];
	NSLog(@"%@", args);
	
  if (status == 0)
	{
		NSLog(@"Task succeeded.");
		if ([args length] > 4)
		{
			NSString *path = [args objectAtIndex:4];
			NSArray *eject = [NSArray arrayWithObjects:@"eject", @"-quiet", path, nil];
			[NSTask launchedTaskWithLaunchPath:@"/usr/bin/hdiutil" arguments:eject];
		}
		
	}
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

- (void)observeWorkspace: (NSNotification*)notification
{
	id ui = [notification userInfo];
	id path = [ui valueForKey:@"NSDevicePath"];
	id volName = [ui valueForKey:@"NSWorkspaceVolumeLocalizedNameKey"];
	
	NSLog(@"Imaging: %@", volName);
	
	NSTask *dmg = [[NSTask alloc] init];
	NSMutableArray *args = [NSMutableArray arrayWithObjects:@"create",
						   @"-format",
						   @"UDBZ",
						   @"-srcfolder",
						   path,
						   volName,
						   nil];
	
	[dmg setCurrentDirectoryPath:@"/tmp/"];
	[dmg setLaunchPath:@"/usr/bin/hdiutil"];
	[dmg setArguments:args];
	[dmg launch];
	
}

@end

int main (int argc, const char * argv[])
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  
  //NSRunLoop *rl = [NSRunLoop currentRunLoop];
  //[[Imager alloc] init];
  //[rl run];
  NSLog(@"%d", argv[1]);
  [pool release];
  return 0;
}
