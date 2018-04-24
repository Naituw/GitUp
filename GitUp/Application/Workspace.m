//
//  Workspace.m
//  Application
//
//  Created by Wu Tian on 2018/4/24.
//

#import "Workspace.h"
#import <GitUpKit/GitUpKit.h>

@interface WorkspaceRepo ()
{
  BOOL _initialized;
}

@property (nonatomic, strong) GCLiveRepository * repository;
@property (nonatomic, strong) NSString * rootDirectory;
@property (nonatomic, assign) NSUInteger unreadCount;

@end

@implementation WorkspaceRepo

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithRootDirectory:(NSString *)root repository:(GCLiveRepository *)repository
{
  if ((self = [self init])) {
    _rootDirectory = root;
    _repository = repository;
    _repository.statusMode = kGCLiveRepositoryStatusMode_Normal;
    
    NSString * fullPath = _repository.workingDirectoryPath;
    if ([fullPath hasPrefix:_rootDirectory]) {
      fullPath = [fullPath substringFromIndex:_rootDirectory.length];
      if (fullPath.length > 1 && [fullPath hasPrefix:@"/"]) {
        fullPath = [fullPath substringFromIndex:1];
      }
      if (fullPath.length == 0) {
        fullPath = [_rootDirectory lastPathComponent];
      }
      _relativePath = fullPath;
    } else {
      NSAssert(NO, @"Repo Not Inside Workspace");
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_repoChange:) name:GCLiveRepositoryDidChangeNotification object:_repository];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [self updateUnreadCount];
    
    _initialized = YES;
  }
  return self;
}

- (void)setUnreadCount:(NSUInteger)unreadCount
{
  if (_unreadCount != unreadCount) {
    _unreadCount = unreadCount;
    
    if (_initialized) {
      [[NSNotificationCenter defaultCenter] postNotificationName:WorkspaceRepoDidUpdateUnreadCountNotification object:self];
    }
  }
}

- (void)updateUnreadCount
{
  self.unreadCount = _repository.workingDirectoryStatus.deltas.count;
}

- (void)_repoChange:(NSNotification *)notification
{
  [self updateUnreadCount];
}

- (void)_applicationActive:(NSNotification *)notification
{
  [_repository notifyWorkingDirectoryChanged];
  [self updateUnreadCount];
}

@end

NSString * const WorkspaceRepoDidUpdateUnreadCountNotification = @"WorkspaceRepoDidUpdateUnreadCountNotification";

@interface Workspace ()

@property (nonatomic, strong) NSString * rootDirectory;

@end

@implementation Workspace

- (instancetype)initWithDirectory:(NSString *)directory
{
  if ((self = [self init])) {
    _rootDirectory = directory;
    [self startLoadingRepos];
  }
  return self;
}

- (void)startLoadingRepos
{
  CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
  _repos = [self _findReposInsideDirectory:_rootDirectory levels:3];
  
  NSLog(@"time: %f", CFAbsoluteTimeGetCurrent() - start);
}

- (NSArray<WorkspaceRepo *> *)_findReposInsideDirectory:(NSString *)directory levels:(NSUInteger)levels
{
  NSMutableArray<WorkspaceRepo *> * repos = [NSMutableArray array];

  GCLiveRepository * repository = [[GCLiveRepository alloc] initWithExistingLocalRepository:directory error:NULL];
  if (repository) {
    WorkspaceRepo * repo = [[WorkspaceRepo alloc] initWithRootDirectory:_rootDirectory repository:repository];
    [repos addObject:repo];
  }
  
  levels--;
  if (levels > 0) {
    NSArray<NSString *> * dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
    for (NSString * dir in dirs) {
      if ([[dir lastPathComponent] hasPrefix:@"."]) {
        continue;
      }
      [repos addObjectsFromArray:[self _findReposInsideDirectory:[directory stringByAppendingPathComponent:dir] levels:levels]];
    }
  }
  
  return repos;
}

@end


