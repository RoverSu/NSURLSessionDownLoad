//
//  Manager.h
//  下载管理
//
//  Created by Mac on 16/6/14.
//  Copyright © 2016年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Manager : NSObject

- (void)downloader:(NSURL *)url successBlock:(void(^)(NSURL *path))successBlock processBlock:(void(^)(float process))processBlock errorBlock:(void(^)(NSError *error))errorBlock;

+ (instancetype)sharedManager;
- (void)pause;
//- (void)resumee;

@end
