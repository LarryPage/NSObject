//
//  City.h
//  GreenBaby
//
//  Created by LiXiangCheng on 15/7/29.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

//城市
@interface City : NSObject

@property (nonatomic, assign) NSInteger cityid;
@property (nonatomic, strong) NSString *cityname;
@property (nonatomic, strong) NSString *pinyin_first;
@property (nonatomic, strong) NSString *pinyin_second;
@property (nonatomic, strong) NSString *pinyin_full;
@property (nonatomic, assign) NSInteger regionid;//省分ID

@property (nonatomic, strong) NSString *record_id;//PK,用于数据存储

// 查找指定cityname的城市记录//用于gprs定位城市
+ (City *)findRecordbyGprs:(NSString *)_cityname;

@end
