//
//  Configs.m
//  BBPush
//
//  Created by Li XiangCheng on 13-3-10.
//  Copyright (c) 2013年 Li XiangCheng. All rights reserved.
//

#import "Configs.h"

@implementation Configs

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (NSLocale*) CurrentLocale {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	NSArray* languages = [defaults objectForKey:@"AppleLanguages"];
	if (languages.count > 0) {
		NSString* currentLanguage = [languages objectAtIndex:0];
		return [[NSLocale alloc] initWithLocaleIdentifier:currentLanguage];
	} else {
		return [NSLocale currentLocale];
	}
}
+ (NSString*) LocalizedString:(NSString*)key {//comment:没有返回key
	static NSBundle* bundle = nil;
	if (!bundle) {
		NSString* path = [[[NSBundle mainBundle] resourcePath]
						  stringByAppendingPathComponent:@"LocalizedString.bundle"];
		bundle = [[NSBundle bundleWithPath:path] copy];
	}
	
	return [bundle localizedStringForKey:key value:key table:nil];
}

+ (NSString*)documentPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}
+ (NSString*) PathForBundleResource:(NSString*) relativePath{
	NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
	return [resourcePath stringByAppendingPathComponent:relativePath];
}
+ (NSString*) PathForDocumentsResource:(NSString*) relativePath{
	static NSString* documentsPath = nil;
	if (!documentsPath) {
		NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		documentsPath = [[dirs objectAtIndex:0] copy];
	}
	return [documentsPath stringByAppendingPathComponent:relativePath];
}

+ (NSDictionary *)faceMap {
    static NSDictionary *faceMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
        if ([[languages objectAtIndex:0] hasPrefix:@"zh"]) {
            
            faceMap = [NSDictionary dictionaryWithContentsOfFile:
                         [[NSBundle mainBundle] pathForResource:@"faceMap_ch"
                                                         ofType:@"plist"]];
        }
        else {
            
            faceMap = [NSDictionary dictionaryWithContentsOfFile:
                         [[NSBundle mainBundle] pathForResource:@"faceMap_en"
                                                         ofType:@"plist"]];
        }
    });
    return faceMap;
}

#pragma mark - memoryDB and files

+ (NSString*)SystemInfoCurRecordPlistPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"SystemInfoCurRecord1.plist"];
}
+ (NSString*)UserInfoCurRecordPlistPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"UserInfoCurRecord1.plist"];
}
+ (NSString*)CityRecordPlistPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"CityRecord1.plist"];
    //return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"CityRecord1.plist"];//Mock
}
+ (NSString*)RegionRecordPlistPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"RegionRecord1.plist"];
}
+ (NSString*)MessageDetailRecordPlistPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"MessageDetailRecord1.plist"];
}

#pragma mark - memoryDB and sqlite3

+ (NSString*)dbPath{
    return [[Configs documentPath] stringByAppendingPathComponent:@"db.db"];
}

+ (NSString*)SystemInfoCurRecordTableName{
    return @"SystemInfoCurRecord1";
}
+ (NSString*)UserInfoCurRecordTableName{
    return @"UserInfoCurRecord1";
}
+ (NSString*)CityRecordTableName{
    return @"CityRecord1";
}
+ (NSString*)RegionRecordTableName{
    return @"RegionRecord1";
}
+ (NSString*)MessageDetailRecordTableName{
    return @"MessageDetailRecord1";
}

@end
