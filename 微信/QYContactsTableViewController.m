//
//  QYContactsTableViewController.m
//  微信
//
//  Created by 青云-wjl on 15/9/22.
//  Copyright (c) 2015年 河南青云信息技术有限公司. All rights reserved.
//

#import "QYContactsTableViewController.h"
#import "QYFriendGroup.h"
#import "QYFirend.h"

#import "QYHeaderView.h"
@interface QYContactsTableViewController ()<UISearchResultsUpdating>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *filterFriends;
@property (nonatomic) BOOL isSearching;
@end

@implementation QYContactsTableViewController

-(void)awakeFromNib
{
    //渲染,在tableBar上添加图片
    UIImage *image = [[UIImage imageNamed:@"tabbar_contacts"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *selectedImage = [[UIImage imageNamed:@"tabbar_contactsHL"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    //添加图片和标题（含高亮）
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"通讯录" image:image selectedImage:selectedImage];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //默认不显示搜索框｛contentOffset（偏移量）44为Navergation的高度，tableview的headerView上添加搜索框｝
    self.tableView.contentOffset = CGPointMake(0, 44);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setRightBarButtonItem];
    [self setSearchBarForTableHeaderView];
    [self configDataSource];
}

//在tableview的headerView上添加搜索框
-(void)setSearchBarForTableHeaderView
{
    //初始化的时候SearchResultsController参数传空nil就是把当前视图器作为显示结果的视图器
    // Pass nil if you wish to display search results in the same view that you are searching.
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    
    //当searchController出现时隐藏NavigationBar
    _searchController.hidesNavigationBarDuringPresentation = YES;
    
    _searchController.dimsBackgroundDuringPresentation = NO;
    _searchController.searchBar.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44);
    
    //设置更新搜索结果的代理为self（非常重要！！！）
    _searchController.searchResultsUpdater = self;
    
    self.tableView.tableHeaderView = _searchController.searchBar;
}
//设置导航栏上右边的编辑
-(void)setRightBarButtonItem
{
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}
//编辑  完成  切换
- (void)edit:(UIBarButtonItem *)sender {
    
    if ([sender.title isEqualToString:@"编辑"]) {
        sender.title = @"完成";
        [self.tableView setEditing:YES animated:YES];
    } else {
        sender.title = @"编辑";
        [self.tableView setEditing:NO animated:YES];
    }
}
//配置数据源
-(void)configDataSource
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"friends" ofType:@"plist"];
    NSArray *array = [NSArray arrayWithContentsOfFile:path];
    
    NSMutableArray *groups = [NSMutableArray array];
    for (NSDictionary *dic in array) {
        QYFriendGroup *friendGroup = [QYFriendGroup friendGroupWithDictionary:dic];
        [groups addObject:friendGroup];
    }
    _groups = groups;
    _filterFriends = groups;
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_isSearching) {
        return 1;
    }
    return _groups.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isSearching) {
        return _filterFriends.count;
    }
    
    QYFriendGroup *friendGroup = _groups[section];
    if (friendGroup.isOpen) {
        return friendGroup.friends.count;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identify = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identify];
    }
    
    QYFirend *friend = nil;
    if (_isSearching) {
        friend = _filterFriends[indexPath.row];
    }else{
        QYFriendGroup *friendGroup = _groups[indexPath.section];
        friend = friendGroup.friends[indexPath.row];
    }
    
    cell.imageView.image = [UIImage imageNamed:friend.icon];
    cell.textLabel.text = friend.name;
    cell.detailTextLabel.text = friend.status;
    cell.textLabel.textColor = friend.vip ? [UIColor redColor] : [UIColor blackColor];
    return cell;
}

//允许编辑
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
//编辑的风格是删除
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

//实现删除
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //取到friendGroup（section）
        QYFriendGroup *friendGroup = self.groups[indexPath.section];
        //取到具体删除的单元格
        [friendGroup.friends removeObjectAtIndex:indexPath.row];
             
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

//可以移动
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

//实现移动
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    //找到section
    QYFriendGroup *fromFriendGroup = self.groups[fromIndexPath.section];
    //找到cell
    QYFirend *friend = fromFriendGroup.friends[fromIndexPath.row];
    //取走目标cell
    [fromFriendGroup.friends removeObjectAtIndex:fromIndexPath.row];
    //找到添加位置的section
    QYFriendGroup *toFriendGroup = self.groups[toIndexPath.section];
    //找到具体位置，
    [toFriendGroup.friends insertObject:friend atIndex:toIndexPath.row];
    
}


#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_isSearching) {
        return 0;
    }
    return 44;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_isSearching) {
        return nil;
    }
    QYHeaderView *qyHeaderView = [QYHeaderView headerViewWithTableView:tableView];
    qyHeaderView.group = _groups[section];
    
    qyHeaderView.headerViewClick = ^(){
        [tableView reloadData];
    };
    return qyHeaderView;
}


#pragma mark - UISearchResultsUpdating
//必须实现的代理方法
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *filterStr = searchController.searchBar.text;
    // 如果filteredStr为nil，或者为空字符串@""
    if (!filterStr || filterStr.length == 0) {
        //是否在搜索状态
        _isSearching = NO;
        //把搜索数据给搜索结果
        _filterFriends = _groups;
    } else {
        _isSearching = YES;
        
        //单元格里面的数据对应的是QYFriend
        //拿单元格中的friend.name跟搜索框中的text进行比较
        //谓语,即设置搜索条件。SELF在本例中就是QYFriend的模型对象，
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", filterStr];
        
        NSMutableArray *filtedArray = [NSMutableArray array];
        for (QYFriendGroup *fg in _groups) {
            NSArray *array = [fg.friends filteredArrayUsingPredicate:predicate];
            [filtedArray addObjectsFromArray:array];
        }
        _filterFriends = filtedArray;
    }
    //刷新
    [self.tableView reloadData];
}

@end
