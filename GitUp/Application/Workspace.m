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

@property (nonatomic, strong) GCRepository * repository;
@property (nonatomic, strong) NSString * rootDirectory;
@property (nonatomic, assign) NSUInteger unreadCount;

@end

@implementation WorkspaceRepo

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithWorkspace:(Workspace *)workspace repository:(GCRepository *)repository
{
  if ((self = [self init])) {
    _workspace = workspace;
    _rootDirectory = workspace.rootDirectory;
    _repository = repository;
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationActive:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_repositoryChanged:) name:GCLiveRepositoryStatusDidUpdateNotification object:nil];
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
  NSError * error = nil;
  GCDiff * diff = [_repository diffWorkingDirectoryWithHEAD:nil options:kGCDiffOption_FindRenames | kGCDiffOption_IncludeUntracked maxInterHunkLines:0 maxContextLines:3 error:&error];
  self.unreadCount = diff.deltas.count;
}

- (void)_repositoryChanged:(NSNotification *)notification
{
  GCLiveRepository * repo = notification.object;
  if ([self.repository.repositoryPath isEqual:repo.repositoryPath]) {
    [self updateUnreadCount];
  }
}

- (void)_applicationActive:(NSNotification *)notification
{
  [self updateUnreadCount];
}

@end

NSString * const WorkspaceRepoDidUpdateUnreadCountNotification = @"WorkspaceRepoDidUpdateUnreadCountNotification";

@interface Workspace ()
{
  struct {
    unsigned int scheduledAppending: 1;
  } _flags;
}

@property (nonatomic, strong) NSString * rootDirectory;
@property (nonatomic, strong) NSMutableArray<WorkspaceRepo *> * repos;
@property (nonatomic, strong) NSMutableArray<WorkspaceRepo *> * batchAppendRepos;

@end

@implementation Workspace

- (instancetype)initWithDirectory:(NSString *)directory
{
  if ((self = [self init])) {
    _rootDirectory = directory;
    _repos = [NSMutableArray array];
    _batchAppendRepos = [NSMutableArray array];
    
    [self startLoadingRepos];
  }
  return self;
}

- (void)_foundRepository:(WorkspaceRepo *)repo
{
  if (repo) {
    [_batchAppendRepos addObject:repo];
    if (!_flags.scheduledAppending) {
      _flags.scheduledAppending = YES;
      // throttling
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _flags.scheduledAppending = NO;
        [self _batchAppendRepos:_batchAppendRepos];
        [_batchAppendRepos removeAllObjects];
      });
    }
  }
}

- (void)_batchAppendRepos:(NSArray<WorkspaceRepo *> *)repos
{
  if (repos.count) {
    [_repos addObjectsFromArray:repos];
    [[NSNotificationCenter defaultCenter] postNotificationName:WorkspaceDidUpdateReposNotification object:self userInfo:@{WorkspaceNotificationAppendedReposKey: repos}];
  }
}

- (void)startLoadingRepos
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self _findReposInsideDirectory:_rootDirectory levels:3 each:^(WorkspaceRepo * repo) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _foundRepository:repo];
      });
    }];
  });
}

- (void)_findReposInsideDirectory:(NSString *)directory levels:(NSUInteger)levels each:(void (^)(WorkspaceRepo * ))eachBlock
{
  GCRepository * repository = [[GCRepository alloc] initWithExistingLocalRepository:directory error:NULL];
  if (repository) {
    WorkspaceRepo * repo = [[WorkspaceRepo alloc] initWithWorkspace:self repository:repository];
    if (eachBlock) {
      eachBlock(repo);
    }
  }
  
  levels--;
  if (levels > 0) {
    NSArray<NSString *> * dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
    for (NSString * dir in dirs) {
      if ([[dir lastPathComponent] hasPrefix:@"."]) {
        continue;
      }
      [self _findReposInsideDirectory:[directory stringByAppendingPathComponent:dir] levels:levels each:eachBlock];
    }
  }
}

@end

NSString * const WorkspaceDidUpdateReposNotification = @"WorkspaceDidUpdateReposNotification";
NSString * const WorkspaceNotificationAppendedReposKey = @"WorkspaceNotificationAppendedReposKey";
