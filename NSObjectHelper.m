

#import "NSObjectHelper.h"

static NSMutableDictionary *gPropertiesOfClass = nil;//缓存所有类的属性{"ClassName":propertiesDic}=Table scheme
static NSMutableDictionary *gRecordDicOfClass = nil;//缓存所有类的历史记录{"ClassName":RecordDicArray}=Table Data
static NSMutableDictionary *gCurRecordDicOfClass = nil;//缓存所有类的当前记录{"ClassName":RecordDic}=Table row
static FMDatabaseQueue *gFMDBQueue = nil;//缓存数据库操作队列

@implementation NSObject (Helper)

//NSObject提供 的performSelector最多只支持两个参数,针对NSObject增加了如下扩展
- (id)performSelector:(SEL)selector withObjects:(NSArray *)objects {
    NSMethodSignature *signature = [self methodSignatureForSelector:selector];
    if (signature) {
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:selector];
        for(int i = 0; i < [objects count]; i++){
            id object = [objects objectAtIndex:i];
            [invocation setArgument:&object atIndex: (i + 2)];
        }
        [invocation invoke];
        if (signature.methodReturnLength) {
            id anObject;
            [invocation getReturnValue:&anObject];
            return anObject;
        } else {
            return nil;
        }
    } else {
        return nil;
    }
}

@end

@implementation NSObject (KVC)

- (id)initWithDic:(NSDictionary *)dic{
    self = [self init];
    if (self) {
        if (!dic || ![dic isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        
        [NSObject KeyValueDecoderForObject:self dic:dic];
    }
    return self;
}

- (NSDictionary *)dic{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [NSObject KeyValueEncoderForObject:self dic:dic];
    
    return dic;
}

+ (void)KeyValueDecoderForObject:(id)object dic:(NSDictionary *)dic{
    NSDictionary *propertysDic = [self propertiesOfObject:object];
    [propertysDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqualToString:NSStringFromClass([NSString class])] || [obj isEqualToString:NSStringFromClass([NSMutableString class])]) {
            NSMutableString *value=RKMapping([dic valueForKey:key]);
            [object setValue:value forKeyPath:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSDictionary class])] || [obj isEqualToString:NSStringFromClass([NSMutableDictionary class])]) {
            NSMutableDictionary *value=RKMapping([dic valueForKey:key]);
            [object setValue:value forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_LNG_LNG]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_INT]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_LNG]]) {//NSInteger
            NSInteger value=[RKMapping([dic valueForKey:key]) integerValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_ULNG_LNG]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_UINT]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_ULNG]]) {//NSUInteger
            NSUInteger value=[RKMapping([dic valueForKey:key]) integerValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_DBL]]) {//double
            double value=[RKMapping([dic valueForKey:key]) doubleValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_FLT]]) {//float
            float value=[RKMapping([dic valueForKey:key]) floatValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_INT]]) {//int
            int value=[RKMapping([dic valueForKey:key]) intValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_BOOL]]) {//bool,BOOL
            bool value=[RKMapping([dic valueForKey:key]) boolValue];
            [object setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSSet class])] || [obj isEqualToString:NSStringFromClass([NSMutableSet class])]) {
        }
        else if ([obj isEqualToString:NSStringFromClass([NSArray class])] || [obj isEqualToString:NSStringFromClass([NSMutableArray class])]) {
            NSMutableArray *value=[[NSMutableArray alloc] init];
            
            NSMutableArray *records = RKMapping([dic valueForKey:key]);
            for (NSObject *record in records) {
                if (!record || ![record isKindOfClass:[NSObject class]]) {
                    continue;
                }
                [value addObject:record];
            }
            
            [object setValue:value forKeyPath:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSOrderedSet class])] || [obj isEqualToString:NSStringFromClass([NSMutableOrderedSet class])]) {
        }
        else{//自定义class
            NSRegularExpression *arrayRegExp=[[NSRegularExpression alloc] initWithPattern:@"(?<=\\<).*?(?=\\>)" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *results=[arrayRegExp matchesInString:obj options:NSMatchingWithTransparentBounds range:NSMakeRange(0, [obj length])];
            if (results.count>0) {
                NSTextCheckingResult *result=results[0];
                NSRange range = result.range;
                NSString *className = [[obj substringToIndex:range.location-1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *recordClassName = [[obj substringWithRange:range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([className isEqualToString:NSStringFromClass([NSArray class])] || [className isEqualToString:NSStringFromClass([NSMutableArray class])]) {
                    id recordClass = NSClassFromString(recordClassName);
                    
                    NSMutableArray *value=[[NSMutableArray alloc] init];
                    
                    NSMutableArray *records = RKMapping([dic valueForKey:key]);
                    for (NSDictionary *record in records) {
                        if (!record || ![record isKindOfClass:[NSDictionary class]]) {
                            continue;
                        }
                        if([recordClass instancesRespondToSelector:@selector(initWithDic:)]){
                            [value addObject:[[recordClass alloc] initWithDic:record]];
                        }
                    }
                    
                    [object setValue:value forKeyPath:key];
                    return;
                }
            }
            
            id aClass = NSClassFromString(obj);
            if([aClass instancesRespondToSelector:@selector(initWithDic:)]){
                [object setValue:[[aClass alloc] initWithDic:[dic valueForKey:key]] forKeyPath:key];
            }
        }
    }];
}

+ (void)KeyValueEncoderForObject:(id)object dic:(NSDictionary *)dic{
    NSDictionary *propertysDic = [self propertiesOfObject:object];
    [propertysDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isEqualToString:NSStringFromClass([NSString class])] || [obj isEqualToString:NSStringFromClass([NSMutableString class])]) {
            NSMutableString *value=[object valueForKeyPath:key];
            [dic setValue:(value?value:@"") forKeyPath:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSDictionary class])] || [obj isEqualToString:NSStringFromClass([NSMutableDictionary class])]) {
            NSMutableDictionary *value=[object valueForKeyPath:key];
            [dic setValue:(value?value:[NSMutableDictionary dictionary]) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_LNG_LNG]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_INT]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_LNG]]) {//NSInteger
            NSInteger value=[[object valueForKeyPath:key] integerValue];
            [dic setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_ULNG_LNG]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_UINT]]
                 || [obj isEqualToString:[NSString stringWithFormat:@"%c",_C_ULNG]]) {//NSUInteger
            NSUInteger value=[[object valueForKeyPath:key] integerValue];
            [dic setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_DBL]]) {//double
            double value=[[object valueForKeyPath:key] doubleValue];
            [dic setValue:[NSString stringWithFormat:@"%0.6f", value] forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_FLT]]) {//float
            double value=[[object valueForKeyPath:key] floatValue];
            [dic setValue:[NSString stringWithFormat:@"%0.6f", value] forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_INT]]) {//int
            int value=[[object valueForKeyPath:key] intValue];
            [dic setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:[NSString stringWithFormat:@"%c",_C_BOOL]]) {//bool,BOOL
            bool value=[[object valueForKeyPath:key] boolValue];
            [dic setValue:@(value) forKeyPath:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSSet class])] || [obj isEqualToString:NSStringFromClass([NSMutableSet class])]) {
        }
        else if ([obj isEqualToString:NSStringFromClass([NSArray class])] || [obj isEqualToString:NSStringFromClass([NSMutableArray class])]) {
            NSMutableArray *value=[NSMutableArray array];
            
            NSMutableArray *records=[object valueForKeyPath:key];
            [records enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSObject *record = (NSObject *)obj;
                [value addObject:record];
            }];
            [dic setValue:value forKey:key];
        }
        else if ([obj isEqualToString:NSStringFromClass([NSOrderedSet class])] || [obj isEqualToString:NSStringFromClass([NSMutableOrderedSet class])]) {
        }
        else{//自定义class
            NSRegularExpression *arrayRegExp=[[NSRegularExpression alloc] initWithPattern:@"(?<=\\<).*?(?=\\>)" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *results=[arrayRegExp matchesInString:obj options:NSMatchingWithTransparentBounds range:NSMakeRange(0, [obj length])];
            if (results.count>0) {
                NSTextCheckingResult *result=results[0];
                NSRange range = result.range;
                NSString *className = [[obj substringToIndex:range.location-1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *recordClassName = [[obj substringWithRange:range] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([className isEqualToString:NSStringFromClass([NSArray class])] || [className isEqualToString:NSStringFromClass([NSMutableArray class])]) {
                    id recordClass = NSClassFromString(recordClassName);
                    
                    NSMutableArray *value=[NSMutableArray array];
                    
                    NSMutableArray *records=[object valueForKeyPath:key];
                    [records enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if([recordClass instancesRespondToSelector:@selector(dic)]){
                            [value addObject:[obj dic]];
                        }
                        
                    }];
                    
                    [dic setValue:value forKey:key];
                    return;
                }
            }
            
            id aClass = NSClassFromString(obj);
            if([aClass instancesRespondToSelector:@selector(dic)]){
                NSDictionary *value=[[object valueForKeyPath:key] dic];
                [dic setValue:value?value:[NSDictionary dictionary] forKey:key];
            }
        }
    }];
}

//http://stackoverflow.com/questions/754824/get-an-object-properties-list-in-objective-c
static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    //printf("attributes=%s\n", attributes);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {//strsep:分解字符串为一组字符串
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /*
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
             */
            //return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
            NSString *name = [[NSString alloc] initWithBytes:attribute + 1 length:strlen(attribute) - 1 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            //return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
            NSString *name = [[NSString alloc] initWithBytes:attribute + 3 length:strlen(attribute) - 4 encoding:NSASCIIStringEncoding];
            return (const char *)[name cStringUsingEncoding:NSASCIIStringEncoding];
        }
    }
    return "";
}

+ (NSDictionary *)classPropsFor:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];
            [results setObject:propertyType forKey:propertyName];
        }
    }
    free(properties);
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}

//recursive
+ (NSDictionary *) propertiesOfObject:(id)object
{
    Class class = [object class];
    return [self propertiesOfClass:class];
}

+ (NSDictionary *) propertiesOfClass:(Class)klass
{
    //memory缓存
    if (!gPropertiesOfClass) {
        gPropertiesOfClass = [[NSMutableDictionary alloc] init];
    }
    NSMutableDictionary * properties=[gPropertiesOfClass valueForKey:NSStringFromClass(klass)];
    if (properties && properties.count>0) {
    }
    else{
        properties = [NSMutableDictionary dictionary];
        [self propertiesForHierarchyOfClass:klass onDictionary:properties];
        //CLog(@"%@:%@",NSStringFromClass(class),properties);
        [gPropertiesOfClass setValue:properties forKey:NSStringFromClass(klass)];
    }
    return properties;
    
//    NSMutableDictionary * properties = [NSMutableDictionary dictionary];
//    [self propertiesForHierarchyOfClass:class onDictionary:properties];
//    return [NSDictionary dictionaryWithDictionary:properties];
}

+ (NSDictionary *) propertiesOfSubclass:(Class)klass
{
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    return [self propertiesForSubclass:klass onDictionary:properties];
}

+ (NSMutableDictionary *)propertiesForHierarchyOfClass:(Class)class onDictionary:(NSMutableDictionary *)properties
{
    if (class == NULL) {
        return nil;
    }
    
    if (class == [NSObject class]) {
        // On reaching the NSObject base class, return all properties collected.
        return properties;
    }
    
    // Collect properties from the current class.
    [self propertiesForSubclass:class onDictionary:properties];
    
    // Collect properties from the superclass.
    return [self propertiesForHierarchyOfClass:[class superclass] onDictionary:properties];
}

+ (NSMutableDictionary *) propertiesForSubclass:(Class)class onDictionary:(NSMutableDictionary *)properties
{
    unsigned int outCount, i;
    objc_property_t *objcProperties = class_copyPropertyList(class, &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = objcProperties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];
            [properties setObject:propertyType forKey:propertyName];
        }
    }
    free(objcProperties);
    
    return properties;
}

#pragma mark sqlite3

+ (FMDatabaseQueue *)getFMDBQueue{
    if (!gFMDBQueue) {
        NSString *aSelectorName=@"dbPath";
        SEL aSel = NSSelectorFromString(aSelectorName);
        NSString *error=[NSString stringWithFormat:@"Cannot find method:%@",aSelectorName];
        NSAssert([Configs respondsToSelector:aSel],error);
        NSString* path = [Configs performSelector:aSel];
        gFMDBQueue = [FMDatabaseQueue databaseQueueWithPath:path];
        
        [gFMDBQueue inDatabase:^(FMDatabase *db){
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS META (key CHAR(50) PRIMARY KEY  NOT NULL,value TEXT)"];
        }];
    }
    
    Class class = self;
    //1.files
    NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
    SEL aSel = NSSelectorFromString(aSelectorName);
    //2.sqlite3
    NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
    SEL bSel = NSSelectorFromString(bSelectorName);
    if ([Configs respondsToSelector:aSel]) {
    }
    else if ([Configs respondsToSelector:bSel]) {
        NSString* tableName = [Configs performSelector:bSel];
        [gFMDBQueue inDatabase:^(FMDatabase *db){
            NSString *sql=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (key CHAR(100) PRIMARY KEY  NOT NULL,value TEXT)",tableName];
            [db executeUpdate:sql];
        }];
    }
    
    return gFMDBQueue;
/*
    //[gFMDBQueue inDatabase:^(FMDatabase *db){
    [gFMDBQueue inTransaction:^(FMDatabase *db, BOOL *rollback){
        BOOL result = [db executeUpdate:@"CREATE TABLE test (a text, b text, c integer, d double, e double)"];
        result = [db executeUpdate:@"INSERT INTO test VALUES ('a', 'b', 1, 2.2, 2.3)"];
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM test"];
        [rs next];
        [rs close];
    }];
    
    [gFMDBQueue close];
 */
}

#pragma mark load and save CurRecord
+ (NSDictionary *)loadCurRecordDic{
    if (!gCurRecordDicOfClass) {
        gCurRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    __block NSDictionary * curRecordDic=[gCurRecordDicOfClass valueForKey:NSStringFromClass(class)];
    if (!curRecordDic) {
        //1.files
        NSString *aSelectorName=[NSString stringWithFormat:@"%@CurRecordPlistPath",NSStringFromClass(class)];
        SEL aSel = NSSelectorFromString(aSelectorName);
        //2.sqlite3
        NSString *bSelectorName=[NSString stringWithFormat:@"%@CurRecordTableName",NSStringFromClass(class)];
        SEL bSel = NSSelectorFromString(bSelectorName);
        //0.exception
        NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
        NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
        if ([Configs respondsToSelector:aSel]) {
            NSString* path = [Configs performSelector:aSel];
            NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:path];
            if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
                curRecordDic = nil;
            }
            else{
                curRecordDic = dict;
            }
        }
        else if ([Configs respondsToSelector:bSel]) {
            NSString* tableName = [Configs performSelector:bSel];
            [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
                NSDictionary* dict=nil;
                FMResultSet *rs = [db executeQuery:@"SELECT * FROM META WHERE key = ?",tableName];
                if ([rs next]) {
                    dict = [[rs stringForColumn:@"value"] JSONValue];
                }
                [rs close];
                
                if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
                    curRecordDic = nil;
                }
                else{
                    curRecordDic = dict;
                }
            }];
        }
        
        [gCurRecordDicOfClass setValue:curRecordDic forKey:NSStringFromClass(class)];
    }
    return curRecordDic;
}

//清空当前记录
+(void)clearCurRecord{
    if (!gCurRecordDicOfClass) {
        gCurRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    NSDictionary * curRecordDic=[gCurRecordDicOfClass valueForKey:NSStringFromClass(class)];
    curRecordDic = nil;
    [gCurRecordDicOfClass setValue:curRecordDic forKey:NSStringFromClass(class)];
    
    //1.files
    NSString *aSelectorName=[NSString stringWithFormat:@"%@CurRecordPlistPath",NSStringFromClass(class)];
    SEL aSel = NSSelectorFromString(aSelectorName);
    //2.sqlite3
    NSString *bSelectorName=[NSString stringWithFormat:@"%@CurRecordTableName",NSStringFromClass(class)];
    SEL bSel = NSSelectorFromString(bSelectorName);
    //0.exception
    NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
    NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
    if ([Configs respondsToSelector:aSel]) {
        NSString* path = [Configs performSelector:aSel];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    else if ([Configs respondsToSelector:bSel]) {
        NSString* tableName = [Configs performSelector:bSel];
        [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
            BOOL result = [db executeUpdate:@"DELETE FROM META WHERE key = ?",tableName];
        }];
    }
    
    // 通知当前记录已被删除
    NSString *notificationName=[NSString stringWithFormat:@"%@CurRecordChanged",NSStringFromClass(class)];
    // userInfo = NSDictionary {"action":"add"|"delete"}
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"delete", @"action", nil]];
}

//读取当前记录
+ (id)loadCurRecord{
    Class class = self;
    if([class instancesRespondToSelector:@selector(initWithDic:)]){
        return [[class alloc] initWithDic:[self loadCurRecordDic]];
    }
    return nil;
}

//保存当前记录数据
+ (void)saveCurRecordDicData{
    NSDictionary* dict = [NSDictionary dictionaryWithDictionary:[self loadCurRecordDic]];
    [self performSelectorInBackground:@selector(saveCurRecordDic:) withObject:dict];
}

//后台保存当前记录数据
+ (void)saveCurRecordDic:(NSMutableDictionary *)dic{
    @autoreleasepool {
        @synchronized(dic) {//保证此时没有其他线程对self对象进行修改
            Class class = self;
            //1.files
            NSString *aSelectorName=[NSString stringWithFormat:@"%@CurRecordPlistPath",NSStringFromClass(class)];
            SEL aSel = NSSelectorFromString(aSelectorName);
            //2.sqlite3
            NSString *bSelectorName=[NSString stringWithFormat:@"%@CurRecordTableName",NSStringFromClass(class)];
            SEL bSel = NSSelectorFromString(bSelectorName);
            //0.exception
            NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
            NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
            if ([Configs respondsToSelector:aSel]) {
                NSString* path = [Configs performSelector:aSel];
                [dic writeToFile:path atomically:YES];
            }
            else if ([Configs respondsToSelector:bSel]) {
                NSString* tableName = [Configs performSelector:bSel];
                [[self getFMDBQueue] inTransaction:^(FMDatabase *db, BOOL *rollback){
                    [db executeUpdate:@"DELETE FROM META WHERE key = ?",tableName];
                    [db executeUpdate:@"INSERT INTO META (key,value) VALUES (?,?)",tableName,[dic JSONRepresentation]];
                    //[db executeUpdate:@"UPDATE META SET value = ? WHERE key = ?",[dic JSONRepresentation],tableName];
                }];
            }
        }
    }
}
//保存当前记录
+ (BOOL)saveCurRecord:(NSObject *)record{
    BOOL result = NO;
    
    if (!gCurRecordDicOfClass) {
        gCurRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    NSDictionary * curRecordDic=[gCurRecordDicOfClass valueForKey:NSStringFromClass(class)];
    
    NSObject *oldRecord = nil;
    if([class instancesRespondToSelector:@selector(initWithDic:)]){
        oldRecord = [[class alloc] initWithDic:curRecordDic];
    }
    
    if (record && [record isKindOfClass:class]) {
        NSAssert([class instancesRespondToSelector:@selector(dic)],@"Cannot find method:dic");
        curRecordDic=nil;
        curRecordDic=[record dic];
        [gCurRecordDicOfClass setValue:curRecordDic forKey:NSStringFromClass(class)];
        
        // 后台保存到文件中
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveCurRecordDicData) object:nil];
        [self performSelector:@selector(saveCurRecordDicData) withObject:nil afterDelay:1.0];
        
        // 通知当前记录已更新
        NSString *notificationName=[NSString stringWithFormat:@"%@CurRecordChanged",NSStringFromClass(class)];
        // userInfo = NSDictionary {"newRecord":record, "oldRecord":record, "action":"add"|"delete"}
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:record, @"newRecord", oldRecord, @"oldRecord", @"add", @"action", nil]];
        
        result = YES;
    } else {//册除
        //1.files
        NSString *aSelectorName=[NSString stringWithFormat:@"%@CurRecordPlistPath",NSStringFromClass(class)];
        SEL aSel = NSSelectorFromString(aSelectorName);
        //2.sqlite3
        NSString *bSelectorName=[NSString stringWithFormat:@"%@CurRecordTableName",NSStringFromClass(class)];
        SEL bSel = NSSelectorFromString(bSelectorName);
        //0.exception
        NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
        NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
        if ([Configs respondsToSelector:aSel]) {
            NSString* path = [Configs performSelector:aSel];
            result = [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        else if ([Configs respondsToSelector:bSel]) {
            NSString* tableName = [Configs performSelector:bSel];
            [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
                BOOL result = [db executeUpdate:@"DELETE FROM META WHERE key = ?",tableName];
            }];
        }
        
        curRecordDic=nil;
        [gCurRecordDicOfClass setValue:curRecordDic forKey:NSStringFromClass(class)];
        
        // 通知当前记录已被删除
        NSString *notificationName=[NSString stringWithFormat:@"%@CurRecordChanged",NSStringFromClass(class)];
        // userInfo = NSDictionary {"action":"add"|"delete"}
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"delete", @"action", nil]];
    }
    return result;
}

#pragma mark load and save history
+ (NSMutableArray *)loadRecordDicArray {
    if (!gRecordDicOfClass) {
        gRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    __block NSMutableArray * recordDicArray=[gRecordDicOfClass valueForKey:NSStringFromClass(class)];
    if (!(recordDicArray && [recordDicArray isKindOfClass:[NSMutableArray class]] && recordDicArray.count>0)) {
        //1.files
        NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
        SEL aSel = NSSelectorFromString(aSelectorName);
        //2.sqlite3
        NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
        SEL bSel = NSSelectorFromString(bSelectorName);
        //0.exception
        NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
        NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
        if ([Configs respondsToSelector:aSel]) {
            NSString* path = [Configs performSelector:aSel];
            NSArray *records = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
            if (records && [records isKindOfClass:[NSArray class]] && records.count>0) {
                recordDicArray = [NSMutableArray arrayWithArray:records];
            }
            else{
                recordDicArray = [NSMutableArray array];
            }
        }
        else if ([Configs respondsToSelector:bSel]) {
            NSString* tableName = [Configs performSelector:bSel];
            [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
                recordDicArray = [NSMutableArray array];
                NSString *sql=[NSString stringWithFormat:@"SELECT * FROM %@",tableName];
                FMResultSet *rs = [db executeQuery:sql];
                while ([rs next]) {
                    [recordDicArray addObject:[[rs stringForColumn:@"value"] JSONValue]];
                }
                [rs close];
            }];
        }
        
        [gRecordDicOfClass setValue:recordDicArray forKey:NSStringFromClass(class)];
    }
    
    return recordDicArray;
}

//清空记录
+ (void)clearHistory{
    if (!gRecordDicOfClass) {
        gRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    NSMutableArray * recordDicArray=[gRecordDicOfClass valueForKey:NSStringFromClass(class)];
    recordDicArray = nil;
    recordDicArray = [NSMutableArray array];
    [gRecordDicOfClass setValue:recordDicArray forKey:NSStringFromClass(class)];
    
    //1.files
    NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
    SEL aSel = NSSelectorFromString(aSelectorName);
    //2.sqlite3
    NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
    SEL bSel = NSSelectorFromString(bSelectorName);
    //0.exception
    NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
    NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
    if ([Configs respondsToSelector:aSel]) {
        NSString* path = [Configs performSelector:aSel];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    else if ([Configs respondsToSelector:bSel]) {
        NSString* tableName = [Configs performSelector:bSel];
        [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
            NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@",tableName];
            [db executeUpdate:sql];
        }];
    }
}

// 读取记录，返回NSObject的数组
+ (NSMutableArray *)loadHistory{
    Class class = self;
    
    NSArray *records = [self loadRecordDicArray];
    NSMutableArray *history = [NSMutableArray array];
    for (NSDictionary *dic in records) {
        if (!dic || ![dic isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        NSString *record_id = RKMapping([dic valueForKey:@"record_id"]);
        if (record_id && record_id.length>0) {
            if([class instancesRespondToSelector:@selector(initWithDic:)]){
                [history addObject:[[class alloc] initWithDic:dic]];
            }
        }
    }
    
    return history;
}

// 保存记录
+ (void)saveHistoryData{
    if (!gRecordDicOfClass) {
        gRecordDicOfClass = [[NSMutableDictionary alloc] init];
    }
    
    Class class = self;
    NSMutableArray * recordDicArray=[gRecordDicOfClass valueForKey:NSStringFromClass(class)];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:recordDicArray];
    [self performSelectorInBackground:@selector(saveHistory:) withObject:data];
}

// 后台保存记录
+ (void)saveHistory:(NSData *)data{
    @autoreleasepool {
        @synchronized(data) {//保证此时没有其他线程对self对象进行修改,@synchronized它用来修饰一个方法或者一个代码块的时候，能够保证在同一时刻最多只有一个线程执行该段代码.另一个线程必须等待当前线程执行完这个代码块以后才能执行该代码块
            Class class = self;
            NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
            SEL sel = NSSelectorFromString(aSelectorName);
            NSString *error=[NSString stringWithFormat:@"Cannot find method:%@",aSelectorName];
            NSAssert([Configs respondsToSelector:sel],error);
            NSString* path = [Configs performSelector:sel];
            [data writeToFile:path atomically:YES];
        }
    }
}

+ (BOOL)addRecord:(id)record inRecordArray:(NSMutableArray *)recordArray {
    Class class = self;
    if (record && [record isKindOfClass:class]) {
        NSAssert([class instancesRespondToSelector:@selector(dic)],@"Cannot find method:dic");
        NSMutableDictionary *dic = [[record dic] mutableCopy];
        
        // 根据record_id比较是否存在，如果存在则先删除后添加
        for (int i=0; i<recordArray.count; i++) {
            NSDictionary *eachRecord = [recordArray objectAtIndex:i];
            NSString *record_id = RKMapping([eachRecord valueForKey:@"record_id"]);
            NSString *recordid=[record valueForKeyPath:@"record_id"];
            if (record_id && record_id.length>0 && [record_id isEqualToString:recordid]) {
                //存在
                [recordArray removeObjectAtIndex:i];
            }
        }
        
        [recordArray addObject:dic];
        dic=nil;
        return YES;
    }
    return NO;
}

// 添加单条记录
+ (BOOL)addRecord:(NSObject *)record{
    Class class = self;
    if (record && [record isKindOfClass:class]) {
        NSMutableArray* records = [self loadRecordDicArray];
        [self addRecord:record inRecordArray:records];
        
        NSString *notificationName=[NSString stringWithFormat:@"%@HistoryChanged",NSStringFromClass(class)];
        // userInfo = NSDictionary {"action":"add"|"delete"|"update"}
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:record,@"record" ,@"add", @"action", nil]];
        
        //1.files
        NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
        SEL aSel = NSSelectorFromString(aSelectorName);
        //2.sqlite3
        NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
        SEL bSel = NSSelectorFromString(bSelectorName);
        //0.exception
        NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
        NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
        if ([Configs respondsToSelector:aSel]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveHistoryData) object:nil];
            [self performSelector:@selector(saveHistoryData) withObject:nil afterDelay:1.0];
        }
        else if ([Configs respondsToSelector:bSel]) {
            NSString* tableName = [Configs performSelector:bSel];
            [[self getFMDBQueue] inTransaction:^(FMDatabase *db, BOOL *rollback){
                NSString *recordid=[record valueForKeyPath:@"record_id"];
                NSString *sql1=[NSString stringWithFormat:@"DELETE FROM %@ WHERE key = '%@'",tableName,recordid];
                NSString *sql2=[NSString stringWithFormat:@"INSERT INTO %@ (key,value) VALUES ('%@','%@')",tableName,recordid,[[record dic] JSONRepresentation]];
                [db executeUpdate:sql1];
                [db executeUpdate:sql2];
            }];
        }
        return YES;
    } else {
        return NO;
    }
}

// 添加多条记录
+ (BOOL)addRecords:(NSArray *)records{
    Class class = self;
    NSMutableArray *recordFile = [self loadRecordDicArray];
    for (id record in records) {
        if(![self addRecord:record inRecordArray:recordFile])
            return NO;
    }
    
    //1.files
    NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
    SEL aSel = NSSelectorFromString(aSelectorName);
    //2.sqlite3
    NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
    SEL bSel = NSSelectorFromString(bSelectorName);
    //0.exception
    NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
    NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
    if ([Configs respondsToSelector:aSel]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveHistoryData) object:nil];
        [self performSelector:@selector(saveHistoryData) withObject:nil afterDelay:1.0];
    }
    else if ([Configs respondsToSelector:bSel]) {
        NSString* tableName = [Configs performSelector:bSel];
        [[self getFMDBQueue] inTransaction:^(FMDatabase *db, BOOL *rollback){
            for (id record in records) {
                NSString *recordid=[record valueForKeyPath:@"record_id"];
                NSString *sql1=[NSString stringWithFormat:@"DELETE FROM %@ WHERE key = '%@'",tableName,recordid];
                NSString *sql2=[NSString stringWithFormat:@"INSERT INTO %@ (key,value) VALUES ('%@','%@')",tableName,recordid,[[record dic] JSONRepresentation]];
                [db executeUpdate:sql1];
                [db executeUpdate:sql2];
            }
        }];
    }
    return YES;
}

+ (BOOL)updateRecord:(id)record inRecordArray:(NSMutableArray *)recordArray {
    Class class = self;
    if (record && [record isKindOfClass:class]) {
        NSAssert([class instancesRespondToSelector:@selector(dic)],@"Cannot find method:dic");
        NSMutableDictionary *dic = [[record dic] mutableCopy];
        
        // 根据record_id比较是否存在，如果存在则先替换
        for (int i=0; i<recordArray.count; i++) {
            NSDictionary *eachRecord = [recordArray objectAtIndex:i];
            NSString *record_id = RKMapping([eachRecord valueForKey:@"record_id"]);
            NSString *recordid=[record valueForKeyPath:@"record_id"];
            if (record_id && record_id.length>0 && [record_id isEqualToString:recordid]) {
                //存在
                [recordArray replaceObjectAtIndex:i withObject:dic];
            }
        }
        
        dic=nil;
        return YES;
    }
    return NO;
}

//更新单条记录信息
+ (BOOL)updateRecord:(NSObject *)record{
    Class class = self;
    if (record && [record isKindOfClass:class]) {
        NSMutableArray* records = [self loadRecordDicArray];
        [self updateRecord:record inRecordArray:records];
        
        NSString *notificationName=[NSString stringWithFormat:@"%@HistoryChanged",NSStringFromClass(class)];
        // userInfo = NSDictionary {"action":"add"|"delete"|"update"}
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"update", @"action", nil]];
        
        //1.files
        NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
        SEL aSel = NSSelectorFromString(aSelectorName);
        //2.sqlite3
        NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
        SEL bSel = NSSelectorFromString(bSelectorName);
        //0.exception
        NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
        NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
        if ([Configs respondsToSelector:aSel]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveHistoryData) object:nil];
            [self performSelector:@selector(saveHistoryData) withObject:nil afterDelay:1.0];
        }
        else if ([Configs respondsToSelector:bSel]) {
            NSString* tableName = [Configs performSelector:bSel];
            [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
                NSString *recordid=[record valueForKeyPath:@"record_id"];
                NSString *sql=[NSString stringWithFormat:@"UPDATE %@ SET value = '%@' WHERE key = '%@'",tableName,[[record dic] JSONRepresentation],recordid];
                [db executeUpdate:sql];
            }];
        }
        return YES;
    } else {
        return NO;
    }
}

// 删除单条记录
+ (BOOL)deleteRecord:(NSObject *)record{
    Class class = self;
    NSMutableArray* records = [self loadRecordDicArray];
    for (NSDictionary *dic in records) {
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        NSString *record_id = RKMapping([dic valueForKey:@"record_id"]);
        NSString *recordid=[record valueForKeyPath:@"record_id"];
        if (record_id && record_id.length>0 && [record_id isEqualToString:recordid]) {
            //存在
            [records removeObject:dic];
            
            NSString *notificationName=[NSString stringWithFormat:@"%@HistoryChanged",NSStringFromClass(class)];
            // userInfo = NSDictionary {"action":"add"|"delete"}
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"delete", @"action", nil]];
            
            //1.files
            NSString *aSelectorName=[NSString stringWithFormat:@"%@RecordPlistPath",NSStringFromClass(class)];
            SEL aSel = NSSelectorFromString(aSelectorName);
            //2.sqlite3
            NSString *bSelectorName=[NSString stringWithFormat:@"%@RecordTableName",NSStringFromClass(class)];
            SEL bSel = NSSelectorFromString(bSelectorName);
            //0.exception
            NSString *error=[NSString stringWithFormat:@"Cannot find method:(%@ or %@)",aSelectorName,bSelectorName];
            NSAssert(([Configs respondsToSelector:aSel] || [Configs respondsToSelector:bSel]),error);
            if ([Configs respondsToSelector:aSel]) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(saveHistoryData) object:nil];
                [self performSelector:@selector(saveHistoryData) withObject:nil afterDelay:1.0];
            }
            else if ([Configs respondsToSelector:bSel]) {
                NSString* tableName = [Configs performSelector:bSel];
                [[self getFMDBQueue] inDatabase:^(FMDatabase *db){
                    NSString *sql=[NSString stringWithFormat:@"DELETE FROM %@ WHERE key = %@",tableName,recordid];
                    [db executeUpdate:sql];
                }];
            }
            return YES;
        }
    }
    
    return NO;
}

// 是否有此record_id的记录
+ (BOOL)hasRecord:(NSString *)_record_id{
    NSMutableArray* records = [self loadRecordDicArray];
    for (NSDictionary *dic in records) {
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        
        NSString *record_id = RKMapping([dic valueForKey:@"record_id"]);
        if (record_id && record_id.length>0 && [record_id isEqualToString:_record_id]) {
            //存在
            return YES;
        }
    }
    
    return NO;
}

// 查找指定record_id的记录
+ (id)findRecord:(NSString *)_record_id{
    Class class = self;
    NSMutableArray* records = [self loadRecordDicArray];
    for (NSDictionary *dic in records) {
        if (![dic isKindOfClass:[NSDictionary class]]) {
            return nil;
        }
        
        NSString *record_id = RKMapping([dic valueForKey:@"record_id"]);
        if (record_id && record_id.length>0 && [record_id isEqualToString:_record_id]) {
            if([class instancesRespondToSelector:@selector(initWithDic:)]){
                return [[class alloc] initWithDic:dic];
            }
        }
    }
    
    return nil;
}

@end
