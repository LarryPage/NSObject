//
//  Region.m
//  GreenBaby
//
//  Created by LiXiangCheng on 15/7/29.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import "Region.h"

@implementation Region

#pragma mark override

- (id)initWithDic:(NSDictionary *)dic{
    self = [super initWithDic:dic];
    
    self.record_id = [NSString stringWithFormat:@"%@",@(self.regionid)];
    return self;
}

- (NSDictionary *)dic{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[super dic]];
    
    [dic setValue:(self.record_id?self.record_id:@"") forKey:@"record_id"];
    return dic;
}

@end
