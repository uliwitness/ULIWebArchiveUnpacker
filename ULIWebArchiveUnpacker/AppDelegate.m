//
//  AppDelegate.m
//  ULIWebArchiveUnpacker
//
//  Created by Uli Kusterer on 06.05.17.
//  Copyright © 2017 Uli Kusterer. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}


-(BOOL) createFileForResource: (NSDictionary*)dict basePath: (NSString*)basePath
{
	NSData * fileData = dict[@"WebResourceData"];
	NSString * fileName = [dict[@"WebResourceURL"] lastPathComponent];
	NSRange cgiParamOffset = [fileName rangeOfString: @"?"];
	if( cgiParamOffset.location != NSNotFound )
		fileName = [fileName substringToIndex: cgiParamOffset.location];
	fileName = [basePath stringByAppendingPathComponent: fileName];
	
	NSString * utiForMimeType = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag( kUTTagClassMIMEType, (__bridge CFStringRef)dict[@"WebResourceMIMEType"], NULL ));
	NSString * filenameExtension = CFBridgingRelease(UTTypeCopyPreferredTagWithClass( (__bridge CFStringRef)utiForMimeType, kUTTagClassFilenameExtension ));
	if( filenameExtension && ![fileName hasSuffix: filenameExtension] )
		fileName = [fileName stringByAppendingFormat: @".%@", filenameExtension];
	
	return [fileData writeToFile: fileName atomically: YES];
}


-(BOOL) application:(NSApplication *)sender openFile:(NSString *)filename
{
	NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile: filename];
	if( !dict )
		return NO;
	
	NSString * basePath = [filename stringByDeletingPathExtension];
	if( ![[NSFileManager defaultManager] createDirectoryAtPath: basePath withIntermediateDirectories: NO attributes: @{} error: NULL] )
		return NO;
	
	NSMutableDictionary * mainResDict = [dict[@"WebMainResource"] mutableCopy];
	if( [mainResDict[@"WebResourceURL"] hasSuffix: @"/"] )
		mainResDict[@"WebResourceURL"] = @"index";
	if( ![self createFileForResource: mainResDict basePath: basePath] )
		return NO;
	NSArray * subResources = dict[@"WebSubresources"];
	for( NSDictionary * currResource in subResources )
	{
		if( ![self createFileForResource: currResource basePath: basePath] )
			return NO;
	}
	
	return YES;
}

@end
