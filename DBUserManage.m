//
//  DBUserManage.m
//  Doctor
//
//  Created by shufang zou on 2017/6/23.
//  Copyright © 2017年 敬信. All rights reserved.
//

#import "DBUserManage.h"

static DBUserManage *manage = nil;

@implementation DBUserManage
{
    FMDatabase *_db;
}

/**
 使用FMDB 保存推送数据
 
 @return
 */+ (id)shareDBManager{

     if (manage == nil) {
         manage = [[DBUserManage alloc]init];
     }
     return manage;

 }

-(id)init{
    self  =[super init];
    if (self) {
        [self openDBManager];
    }
    return self;
}


- (sqlite3 *)openDBManager{
    
    NSString * path = NSHomeDirectory();
    path = [path stringByAppendingPathComponent:@"Documents/UserIOS.db"];
    NSLog(@"path->%@",path);
    //创建数据库，如果不存在
    _db = [[FMDatabase alloc]initWithPath:path];
    
    //尝试打开数据库
    if ([_db open]) {
        //使用者必须要调用一次此方法，传入需要创建的所有表名
        [self createDBTable];
    }
    return nil;
}


//获取plist文件中模型名称
- (NSArray *)getPlistDBName{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"dbname" ofType:@"plist"];
    
    NSArray *dbArray = [NSArray arrayWithContentsOfFile:path];
    return dbArray;
}


//获取模型中的所有属性名sql语句
-(NSString *)sqlFromModel:(id)model
{
    NSMutableArray *allNames = [[NSMutableArray alloc] init];//存储所有的属性名称
    unsigned int propertyCount = 0;//存储属性的个数
    NSMutableString *sqlString = [[NSMutableString alloc]init]; //存储SQL语句
    ///通过运行时获取当前类的属性
    objc_property_t *propertys = class_copyPropertyList([model class], &propertyCount);
    //把属性放到数组中
    for (int i = 0; i < propertyCount; i ++) {
        objc_property_t property = propertys[i];
        const char * propertyName = property_getName(property);

        [sqlString appendString:[NSString stringWithFormat:@" %@ varchar not NULL",[NSString stringWithUTF8String:propertyName]]];
        if (i != propertyCount-1) {
            [sqlString appendString:@","];
        }
        [allNames addObject:[NSString stringWithUTF8String:propertyName]];
    }
    return sqlString;
}


//获取所有model中的数据值
- (NSDictionary *)dataFromModel:(id)model
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([model class], &outCount);
    for (i = 0; i<outCount; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        id propertyValue = [model valueForKey:(NSString *)propertyName];
        if (propertyValue) [props setObject:propertyValue forKey:propertyName];
    }
    free(properties);
    return props;
}


// 创建表单
- (void)createDBTable{
    @synchronized (self) {
        NSArray *dbArray = [self getPlistDBName];
        
        for (NSString * modelName in dbArray) {
            Class newClass = NSClassFromString(modelName);
            id userModel = [[newClass alloc]init];
            //格式化此模型的建表语句
            NSString * sql =[NSString stringWithFormat:@"create table if not exists %@ (%@);",modelName,[self sqlFromModel:userModel]];
            
            NSLog(@"execute sql:%@",sql);
            BOOL success = [_db executeUpdate:sql];
            if (!success) {
                NSLog(@"创建表格失败:%@",[_db lastErrorMessage]);
            }
            
            //把model中新增属性，插入表单
            unsigned int outCount;
            objc_property_t *properties = class_copyPropertyList([userModel class], &outCount);
            for (int i =0; i <outCount; i++) {
                objc_property_t property = properties[i];
                const char* char_f =property_getName(property);
                NSString *propertyName = [NSString stringWithUTF8String:char_f];
                
                if (![_db columnExists:propertyName inTableWithName:modelName]) {
                    
                    NSString *alertStr = [NSString stringWithFormat:@"alter table %@ add %@ varchar not NULL",modelName,propertyName];
                    BOOL result = [_db executeUpdate:alertStr];
                    if (result == YES) {
                        NSLog(@"Success");
                    }
                }
            }
        }
     }
}


//插入数据
- (void)insertUserWithModel:(id)userModel{
    //格式化插入sql语句
    NSString * sql = @"insert into %@ (%@) values(%@)";
    //获得model对象的属性名和属性值组成的字典
    NSDictionary * dict =  [self dataFromModel:userModel];
    //获得所有属性名组成的字符串，逗号分隔
    NSArray * array = [dict allKeys];
    NSString * namelist = [array componentsJoinedByString:@","];
    NSMutableString * valuelist = [NSMutableString string];
    for (NSInteger i = 0 ; i < array.count; i++) {
        if (i==0) {
            [valuelist appendFormat:@"?"];
        }else{
            [valuelist appendFormat:@",?"];
        }
    }
    //格式化最终的插入语句
    sql = [NSString stringWithFormat:sql, NSStringFromClass([userModel class]),namelist,valuelist];
    NSLog(@"insert sql:%@",sql);
    //变参方法，动态绑定数据
    BOOL success = [_db executeUpdate:sql withArgumentsInArray:[dict allValues]];
    if (!success) {
        NSLog(@"插入失败：%@",[_db lastErrorMessage]);
    }
}


//删除数据
- (void)deleteUser:(NSDictionary *)userD{
    NSArray * array = [userD allKeys];
    NSMutableArray *delete = [[NSMutableArray alloc]init];
    for(NSString *str in array){
        [delete insertObject:str atIndex:0];
    }

    NSString *dbname = [userD objectForKey:delete[0]];
    NSString *value = [userD objectForKey:delete[1]];
    @synchronized (self) {
        NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = '%@'",dbname,delete[1],value];
        //  3.执行语句
        NSLog(@"%@",sql);
       BOOL result = [ _db executeUpdate:sql];
        if (result == YES) {
            NSLog(@"删除成功");
        } else {
            NSLog(@"删除失败");
        }
    }
}


//更新数据
- (void)updateUser:(NSDictionary *)updateDic{
    @synchronized(self){
        NSArray * array = [updateDic allKeys];
        NSMutableArray *update = [[NSMutableArray alloc]init];
        for(NSString *str in array){
            [update insertObject:str atIndex:0];
        }
        NSString *dbname = [updateDic objectForKey:update[0]];
        NSString *requirevalue = [updateDic objectForKey:update[1]];
        NSString * updatevalue= [updateDic objectForKey:update[2]];

        NSString *sql = [NSString stringWithFormat:@"update %@ set %@='%@' where %@ = '%@'",dbname,update[1],requirevalue,update[2],updatevalue];
        BOOL ret = [ _db executeUpdate:sql];
        if (ret == YES) {
            NSLog(@"修改成功");
        }
    }
}



//根据多条件查询数据
- (NSArray *)queryUser:(NSDictionary *)selectDic{
     FMResultSet *set = nil;
     NSMutableArray *userArray = [[NSMutableArray alloc]init];
    @synchronized(self){
        NSArray * array = [selectDic allKeys];
        NSMutableArray *query = [[NSMutableArray alloc]init];
        for(NSString *str in array){
            [query insertObject:str atIndex:0];
        }
        
        NSString *sql = @"";
        NSString *dbname = [selectDic objectForKey:query[0]];
        NSString *key1 = [selectDic objectForKey:query[1]];
        
        if (array.count == 2) {
            sql = [NSString stringWithFormat:@"select *from %@ where %@ ='%@'",dbname,query[1],key1] ;
        }
        if (array.count == 3) {
            NSString *key2 = [selectDic objectForKey:query[2]];

            sql = [NSString stringWithFormat:@"select *from %@ where %@ ='%@' and %@ ='%@'",dbname,query[1],key1,query[2],key2] ;
        }
        //更多条件 在此添加 ....
        
        set = [_db executeQuery:sql];
        while (set.next == YES) {
            NSDictionary *dic = [set resultDictionary];
            [userArray addObject:dic];
        }
    }
    
    NSLog(@"%@",userArray);
    return userArray;
}


//查询某一数据库所有数据
- (NSArray *)queryUsersWithDB:(NSString *)name{
    NSMutableArray *userArray = [[NSMutableArray alloc]init];
    FMResultSet *set = nil;
    @synchronized (self) {
        NSString *sql = [NSString stringWithFormat:@"select *from '%@'",name];
        set = [_db executeQuery:sql];
        while (set.next == YES) {
            NSDictionary *dic = [set resultDictionary];
            [userArray addObject:dic];
        }

    }
    return userArray;
}


//获取所有数据库数据
- (NSArray *)queryAllUsers{
    NSArray *dbArray = [self getPlistDBName];
    NSMutableArray *userArray = [[NSMutableArray alloc]init];
     FMResultSet *set = nil;
    @synchronized (self) {
        for(NSString *name in dbArray){
            NSString *sql = [NSString stringWithFormat:@"select *from '%@'",name];
             set = [_db executeQuery:sql];
            while (set.next == YES) {
                NSDictionary *dic = [set resultDictionary];
                [userArray addObject:dic];
            }
        }
    }
    return userArray;
}


- (int)getNumberOfNotification:(NSString *)dbname{
    NSString *username =[[UserDefaultsHelper sharedInstance]readInfoWithKey:kAppUserName];
    
    NSDictionary *diction = [NSDictionary dictionaryWithObjectsAndKeys:dbname,@"dbname",@"1",@"ischeck",username,@"username", nil];
    
    NSArray *numberA = [self queryUser:diction];
    return (int)numberA.count;
}

@end
