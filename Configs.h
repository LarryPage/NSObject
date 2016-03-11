//
//  Configs.h
//  BBPush
//
//  Created by Li XiangCheng on 13-3-10.
//  Copyright (c) 2013年 Li XiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Configs : NSObject

+ (NSLocale*) CurrentLocale;
+ (NSString*) LocalizedString:(NSString*)key;

+ (NSString*) documentPath;
+ (NSString*) PathForBundleResource:(NSString*) relativePath;
+ (NSString*) PathForDocumentsResource:(NSString*) relativePath;

+ (NSDictionary *)faceMap;//表情字典

#pragma mark - memoryDB and files
+ (NSString*)SystemInfoCurRecordPlistPath;
+ (NSString*)UserInfoCurRecordPlistPath;
+ (NSString*)CityRecordPlistPath;
+ (NSString*)RegionRecordPlistPath;
+ (NSString*)MessageDetailRecordPlistPath;

#pragma mark - memoryDB and sqlite3
+ (NSString*)dbPath;

+ (NSString*)SystemInfoCurRecordTableName;
+ (NSString*)UserInfoCurRecordTableName;
+ (NSString*)CityRecordTableName;
+ (NSString*)RegionRecordTableName;
+ (NSString*)MessageDetailRecordTableName;

@end