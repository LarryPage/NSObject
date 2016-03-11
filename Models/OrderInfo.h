//
//  OrderInfo.h
//  EHome
//
//  Created by LiXiangCheng on 15/7/28.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OrderInfo : NSObject

@property (nonatomic, strong) NSString *contact_name;
@property (nonatomic, strong) NSString *contact_mobile;
@property (nonatomic, strong) NSString *contact_address;

@property (nonatomic, strong) NSString *order_title;
@property (nonatomic, strong) NSString *order_time;
@property (nonatomic, strong) NSString *expired_at;
@property (nonatomic, strong) NSString *service_mobile;
@property (nonatomic, strong) NSDictionary *extend_info;
@property (nonatomic, strong) NSMutableArray *item_list;
/*
 "item_list" =     (
 {
 count = 1;
 "created_at" = "2015-07-17 10:41:08";
 "item_id" = 2;
 name = "1\U6210\U4eba1\U513f\U7ae5";
 "order_id" = 23;
 price = 100;
 status = 1;
 total = 100;
 }
 );
 */
@property (nonatomic, strong) NSString *order_body;
@property (nonatomic, assign) NSInteger order_id;
@property (nonatomic, strong) NSString *order_no;
@property (nonatomic, assign) float order_price;
@property (nonatomic, assign) NSInteger order_status;  //订单状态 0:待支付 1: 待支付－已选择支付方式 2:取消支付 3：支付成功  4:过期

@end
