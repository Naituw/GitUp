//
//  Workspace.h
//  Application
//
//  Created by Wu Tian on 2018/4/24.
//

#import <Foundation/Foundation.h>

@class GCRepository;
@class Workspace;

@interface WorkspaceRepo : NSObject

@property (nonatomic, strong, readonly) GCRepository * repository;
@property (nonatomic, weak, readonly) Workspace * workspace;

@property (nonatomic, strong, readonly) NSString * relativePath;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;

- (void)updateUnreadCount;

@end

extern NSString * const WorkspaceRepoDidUpdateUnreadCountNotification;

@interface Workspace : NSObject

- (instancetype)initWithDirectory:(NSString *)directory;

@property (nonatomic, strong, readonly) NSString * rootDirectory;
@property (nonatomic, strong, readonly) NSArray<WorkspaceRepo *> * repos;

@end

extern NSString * const WorkspaceDidUpdateReposNotification;
extern NSString * const WorkspaceNotificationAppendedReposKey;
