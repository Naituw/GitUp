//
//  Workspace.h
//  Application
//
//  Created by Wu Tian on 2018/4/24.
//

#import <Foundation/Foundation.h>

@class GCLiveRepository;

@interface WorkspaceRepo : NSObject

@property (nonatomic, strong, readonly) GCLiveRepository * repository;

@property (nonatomic, strong, readonly) NSString * relativePath;
@property (nonatomic, assign, readonly) NSUInteger unreadCount;

- (void)updateUnreadCount;

@end

extern NSString * const WorkspaceRepoDidUpdateUnreadCountNotification;

@interface Workspace : NSObject

- (instancetype)initWithDirectory:(NSString *)string;

@property (nonatomic, strong, readonly) NSArray<WorkspaceRepo *> * repos;

@end

