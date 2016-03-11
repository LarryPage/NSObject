//
//  UserInfo.h
//  EHome
//
//  Created by LiXiangCheng on 15/7/28.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject

@property (nonatomic, assign) NSInteger user_id;
@property (nonatomic, strong) NSString *username;  //用户名
@property (nonatomic, strong) NSString *password;  //加密－密码
@property (nonatomic, strong) NSString *basicAuth; //script 脚本代码注入

@property (nonatomic, strong) NSString *mobile;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *avatar;//头像
@property (nonatomic, assign) NSInteger gender;//（性别，1男，0女，2保密未填写，可选）
@property (nonatomic, strong) NSString *birthday;//出行日期

@property (nonatomic, assign) NSInteger push_status;//推送是否关闭
@property (nonatomic, assign) NSInteger news_total;//消息未读总数量

@end

