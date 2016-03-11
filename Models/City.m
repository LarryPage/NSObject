//
//  City.m
//  GreenBaby
//
//  Created by LiXiangCheng on 15/7/29.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import "City.h"

@implementation City

#pragma mark override

- (id)initWithDic:(NSDictionary *)dic{
    self = [super initWithDic:dic];
    
    self.record_id = [NSString stringWithFormat:@"%@",@(self.cityid)];
    return self;
}

- (NSDictionary *)dic{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[super dic]];
    
    [dic setValue:(self.record_id?self.record_id:@"") forKey:@"record_id"];
    return dic;
}

// 查找指定cityname的城市记录//用于gprs定位城市
+ (City *)findRecordbyGprs:(NSString *)_cityname{
    if (_cityname && _cityname.length>0) {
        NSMutableArray* records = [self loadHistory];
        for (City *record in records) {
            NSRange range = [[_cityname lowercaseString] rangeOfString:[record.cityname lowercaseString]];
            if (range.location!=NSNotFound) {
                return record;
            }
            
            range = [[_cityname lowercaseString] rangeOfString:[record.pinyin_full lowercaseString]];
            if (range.location!=NSNotFound) {
                return record;
            }
        }
    }
    
    return nil;
}

@end
