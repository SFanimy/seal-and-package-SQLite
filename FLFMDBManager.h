//
//  FLFMDBManager.h
//  Doctor
//
//  Created by shufang zou on 2017/6/28.
//  Copyright © 2017年 敬信. All rights reserved.
//

#import <Foundation/Foundation.h>


#define FLDB_DEFAULT_NAME @"YaYaSQL"
#define FLFMDBMANAGER [FLFMDBManager shareManager:FLDB_DEFAULT_NAME]
#define FLFMDBMANAGERX(DB_NAME) [FLFMDBManager shareManager:DB_NAME]

@interface FLFMDBManager : NSObject


/**
 创建单例，唯一性

 @param fl_dbName 数据库名称（model的名称）
 @return
 */
+ (instancetype)shareManager:(NSString *)fl_dbName;

#pragma mark -- 创表
/**
 根据类名创建表，如果有则跳过，没有才创建，执行完毕后自动关闭数据库

 @param modelClass 类名
 @return
 */
- (BOOL)fl_createTable:(Class)modelClass;

#pragma mark -- 插入

/**
   插入单个模型或者模型数组
   如果此时传入的模型对应的FLDBID在表中已经存在，则替换更新旧的
   如果没创建表就自动先创建，表名为模型类名
   此时执行完毕后自动关闭数据库

 @param 单个模型或者模型数组
 @return
 */
- (BOOL)fl_insertModel:(id)model;



#pragma mark -- 查询

/**
 查询指定表是否存在，执行完毕后自动关闭数据库

 @param modelClass 表格
 @return
 */
- (BOOL)fl_isExitTable:(Class)modelClass;

/**
 查找指定表中指定条件查询符合的模型，执行完毕后自动关闭数据库

 @param modelClass 指定表格
 @param key 条件键值对的键
 @param value 条件键值对的值
 @return
 */
- (NSArray *)fl_searchRequireArr:(Class)modelClass byRequireKey:(NSString *)key RequireValue:(NSString *)value;

/**
 查找指定表中模型数组（所有的），执行完毕后自动关闭数据库

 @param modelClass 指定表格
 @return
 */
- (NSArray *)fl_searchModelArr:(Class)modelClass;


#pragma mark -- 修改

/**
 修改指定ID的模型（ID在表中具有唯一性），执行完毕后自动关闭数据库

 @param model 指定模型
 @param FLDBID 模型ID
 @return
 */
- (BOOL)fl_modifyModel:(id)model byID:(NSString *)FLDBID;


#pragma mark -- 删除
/**
  删除指定表，执行完毕后自动关闭数据库

 @param modelClass 表
 @return
 */
- (BOOL)fl_dropTable:(Class)modelClass;

/**
 删除所有数据库

 @return 操作不涉及到数据库操作 YES 表示删除成功，NO则删除失败
 */
- (BOOL)fl_dropDB;


/**
 删除指定表格的所有数据，执行完毕后自动关闭数据库
 YES表示删除操作执行成功，NO则操作失败 或者 对应的表格不存在 或者 没有对应数据可以删除

 @param modelClass 表格集合
 @return
 */
- (BOOL)fl_deleteAllModel:(Class)modelClass;

/**
 *  @author animy
 *
 *  删除指定表中指定DBID的模型，执行完毕后自动关闭数据库
 
 *  @return YES表示删除操作执行成功，NO则操作失败 或者 对应的表格不存在 或者 没有对应数据可以删除
 */
- (BOOL)fl_deleteModel:(Class)modelClass byId:(NSString *)FLDBID;

@end
