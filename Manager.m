//
//  Manager.m
//  下载管理
//
//  Created by Mac on 16/6/14.
//  Copyright © 2016年 mac. All rights reserved.
//

#import "Manager.h"
@interface Manager()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, strong) NSData *resumeData;

//回调的block
@property (nonatomic, copy) void (^successBlock)(NSURL *path);
@property (nonatomic, copy) void (^processBlock)(float process);
@property (nonatomic, copy) void (^errorBlock)(NSError *error);

//下载操作缓存池
@property (nonatomic,strong)NSMutableDictionary *cacheDict;

//下载的地址，作为缓存池的key
@property (nonatomic,strong)NSURL *url;

@end

@implementation Manager

//单例方法
+ (instancetype)sharedManager {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    
    return instance;
}

//懒加载
- (NSURLSession *)session {
    if (_session == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
-(NSMutableDictionary *)cacheDict {
    if (_cacheDict == nil) {
        _cacheDict = [NSMutableDictionary dictionary];
    }
    return _cacheDict;
}



- (void)downloader:(NSURL *)url successBlock:(void(^)(NSURL *path))successBlock processBlock:(void(^)(float process))processBlock errorBlock:(void(^)(NSError *error))errorBlock{
    
    self.url = url;
    self.successBlock = successBlock;
    self.processBlock = processBlock;
    self.errorBlock = errorBlock;
    
    //如果有下载操作，返回
    if (self.cacheDict[url.path]) {
        return;
    }
    

    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"123.tmp"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        self.resumeData = [NSData dataWithContentsOfFile:path];
    }
    
    if (self.resumeData != nil) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
        [self.downloadTask resume];
        self.resumeData = nil;
        return;
    }
    
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    self.downloadTask = downloadTask;
    [downloadTask resume];
    
    [self.cacheDict setValue:downloadTask forKey:url.path];

}

//开始下载
- (void)download:(NSURL *)url {
    
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    self.downloadTask = downloadTask;
    [downloadTask resume];
    
}

//暂停
- (void)pause{
   
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        //保存续传的数据
        self.resumeData = resumeData;
        
        //把续传数据保存到沙盒中
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"123.tmp"];
        [self.resumeData writeToFile:path atomically:YES];
        NSLog(@"%@",path);
        self.downloadTask = nil;
    }];
    
}


//代理方法
//下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"%@",[NSThread currentThread]);
    NSLog(@"下载完成 ：%@",location);
    
    if (self.successBlock) {
        self.successBlock(location);
    }
    
    [self.cacheDict removeObjectForKey:self.url.path];
}

//续传的方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"续传");
}

//获取进度的方法
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float process = totalBytesWritten * 1.0 /totalBytesExpectedToWrite;
    NSLog(@"下载进度: %f",process);
}

@end
