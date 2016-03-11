

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "FMDB.h"

@interface NSObject (Helper)
- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects;
@end

///------------------------------
/// @LiXiangCheng 20150327
/// 实现 memoryDB->serializable files、sqlite3
///------------------------------

/**
 auto kvc :variable type

 double
 float
 int
 bool
 BOOL，不建议用
 NSInteger
 NSUInteger
 NSString * NSMutableString *
 NSDictionary * NSMutableDictionary *
 NSArray * NSMutableArray *
 NSSet * NSMutableSet *
 
 and 除了以上其它被认为自定义类
 */
// notificationName (ClassName)CurRecordChanged
// userInfo = NSDictionary {"newRecord":record, "oldRecord":record, "action":"add"|"delete"}
// notificationName (ClassName)HistoryChanged
// userInfo = NSDictionary {"record":record,"action":"add"|"delete"|"update"}

@interface NSObject (KVC)

- (id)initWithDic:(NSDictionary *)dic;
- (NSDictionary *)dic;

+ (void)KeyValueDecoderForObject:(id)object dic:(NSDictionary *)dic;
+ (void)KeyValueEncoderForObject:(id)object dic:(NSDictionary *)dic;

+ (NSDictionary *)classPropsFor:(Class)klass;
//recursive
+ (NSDictionary *) propertiesOfObject:(id)object;
+ (NSDictionary *) propertiesOfClass:(Class)klass;
+ (NSDictionary *) propertiesOfSubclass:(Class)klass;

#pragma mark sqlite3
/*
 Tables:注value存储为dic的josn字符串
 1.META (key TEXT PRIMARY KEY  NOT NULL,value TEXT)
 {(ClassName)CurRecordTableName,[dic JSONRepresentation]}
 2.(ClassName)RecordTableName(key TEXT PRIMARY KEY  NOT NULL,value TEXT)
 {record_id,[dic JSONRepresentation]}
 sql语名:http://www.runoob.com/sqlite/sqlite-tutorial.html
 */
+ (FMDatabaseQueue *)getFMDBQueue;

#pragma mark load and save CurRecord
//清空当前记录
+(void)clearCurRecord;
//读取当前记录
+ (id)loadCurRecord;
//保存当前记录
+ (BOOL)saveCurRecord:(NSObject *)record;

#pragma mark load and save history
//读取记录，返回Dic的数组
+ (NSMutableArray *)loadRecordDicArray;
//清空记录
+ (void)clearHistory;
//读取记录，返回NSObject的数组
+ (NSMutableArray *)loadHistory;
//保存记录
+ (void)saveHistoryData;
//后台保存记录
+ (void)saveHistory:(NSData *)data;
//添加单条记录
+ (BOOL)addRecord:(NSObject *)record;
//添加多条记录
+ (BOOL)addRecords:(NSArray *)records;
//更新单条记录信息
+ (BOOL)updateRecord:(NSObject *)record;
//删除单条记录
+ (BOOL)deleteRecord:(NSObject *)record;
//是否有此record_id的记录
+ (BOOL)hasRecord:(NSString *)_record_id;
//查找指定record_id的记录
+ (id)findRecord:(NSString *)_record_id;

@end
