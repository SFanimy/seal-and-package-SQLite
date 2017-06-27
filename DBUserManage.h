//
//  DBUserManage.h
//  Doctor
//
//  Created by shufang zou on 2017/6/23.
//  Copyright © 2017年 敬信. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "FMDatabaseAdditions.h"

@class push;
@class DBUserModel;


/**
 通用数据库封装类
 可以根据模型自动建表 实现增删改查
 模型类名就是表名 模型属性名就是表的字段名
 */

@interface DBUserManage : NSObject

/**
 使用FMDB 保存推送数据
 
 @return
 */
+ (id)shareDBManager;

/**
 插入数据

 @param userModel 插入的是model的值
 */
- (void)insertUserWithModel:(DBUserModel *)userModel;

/**
 删除数据  注：字典的键要对应的model属性值，且字典需按照给出的顺序来，以方便取值

 @param userD 删除数据集（数据库名称dbname,本数据的唯一id）
 */
- (void)deleteUser:(NSDictionary *)userD;

/**
 更新数据 根据条件修改内容   注：字典的键要对应的model属性值，且字典需按照给出的顺序来，以方便取值

 @param updateDic 更新数据 (数据库名称dbname，根据条件,更改内容）
 */
- (void)updateUser:(NSDictionary *)updateDic;

/**
  查询数据   注：字典的键要对应的model属性值，且字典需按照给出的顺序来，以方便取值

 @param selectDic 条件数据 (数据库dbname，...查询条件）
 @return 数据集
 */
- (NSArray *)queryUser:(NSDictionary *)selectDic;

/**
 查询某一数据库数据

 @param name 数据库名称
 @return 数据组
 */
- (NSArray *)queryUsersWithDB:(NSString *)name;

/**
 查询所有数据

 @return 数据组
 */
- (NSArray *)queryAllUsers;


/**
 获取未读小红点个数

 @param dbname 数据库名称
 @return 红点个数
 */
- (int)getNumberOfNotification:(NSString *)dbname;

@end
