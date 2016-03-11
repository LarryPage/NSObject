//
//  Region.h
//  GreenBaby
//
//  Created by LiXiangCheng on 15/7/29.
//  Copyright (c) 2015年 LiXiangCheng. All rights reserved.
//

#import <Foundation/Foundation.h>

//省份
@interface Region : NSObject

@property (nonatomic, assign) NSInteger regionid;
@property (nonatomic, strong) NSString *regionname;

@property (nonatomic, strong) NSString *record_id;//PK,用于数据存储

@end
