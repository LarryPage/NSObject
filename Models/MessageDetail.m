//
//  MessageDetail.m
//  EHome
//
//  Created by LiXiangCheng on 15/3/30.
//  Copyright (c) 2015年 MeiLin. All rights reserved.
//

#import "MessageDetail.h"

@implementation MessageDetail

#pragma mark override

- (id)initWithDic:(NSDictionary *)dic{
    self = [super initWithDic:dic];
    
    self.record_id = [NSString stringWithFormat:@"%@-%@",@(self.msgid),@(self.msg_type)];
    return self;
}

- (NSDictionary *)dic{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:[super dic]];
    
    [dic setValue:(self.record_id?self.record_id:@"") forKey:@"record_id"];
    return dic;
}

@end
