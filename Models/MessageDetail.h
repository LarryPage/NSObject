//
//  MessageDetail.h
//  EHome
//
//  Created by LiXiangCheng on 15/3/30.
//  Copyright (c) 2015年 MeiLin. All rights reserved.
//

#import <Foundation/Foundation.h>

//消息内容
@interface MessageDetail : NSObject

@property (nonatomic, assign) NSInteger msgid;//消息内容Id,主键值唯一
@property (nonatomic, strong) NSString *time;//"2015-03-25 15:32:20"
@property (nonatomic, strong) NSString *content;
@property (nonatomic, assign) NSInteger status;//0--未读，1--已读
@property (nonatomic, assign) NSInteger unread;//未读数
@property (nonatomic, assign) NSInteger msg_type;//消息类型（1.文本含emoji,2.图片,3.WebPage)
@property (nonatomic, strong) NSString *image;//2.图片,3.WebPage
@property (nonatomic, assign) NSInteger gender;//（性别，1男，2女，0未填写，可选）
@property (nonatomic, strong) NSString *title;//3.WebPage
@property (nonatomic, strong) NSString *page_url;//3.WebPage

@property (nonatomic, assign) NSInteger fromuid;
@property (nonatomic, assign) NSInteger touid;
@property (nonatomic, strong) NSString *fromuname;
@property (nonatomic, strong) NSString *touname;
@property (nonatomic, strong) NSString *avatar;//对方头像

@property (nonatomic, strong) NSString *record_id;//PK,用于数据存储

@end
