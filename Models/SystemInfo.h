//
//  SystemInfo.h
//  EHome
//
//  Created by LiXiangCheng on 15/7/28.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SystemInfo : NSObject

@property (nonatomic, strong) NSString *pushToken;  //APNS推送的pushtoken
@property (nonatomic, strong) NSString *welcome_img;  //欢迎图

@property (nonatomic, strong) NSString *my_order_url;  //我的订单链接
@property (nonatomic, strong) NSString *my_wallet_url;  //我的钱包链接

@end
