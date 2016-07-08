//
//  CLAlbumTableView.m
//  Tiaooo
//
//  Created by ClaudeLi on 16/7/2.
//  Copyright © 2016年 ClaudeLi. All rights reserved.
//

#import "CLAlbumTableView.h"
#import "CLAssetCell.h"
#import "CLPhotoLib.h"

static CGFloat tableHeight;
@interface CLAlbumTableView ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation CLAlbumTableView

#pragma mark -
#pragma mark -- -- -- -- -- - Get & Set - -- -- -- -- --

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [self setupTableView];
        [self addSubview:self.tableView];
    }
    return self;
}

- (void)setAlbumArray:(NSMutableArray *)albumArray{
    _albumArray = albumArray;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark -- -- -- -- -- - UITableView Delegate & DataSource - -- -- -- -- --
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.albumArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return CLAlbumRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CLAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CLAlbumCell"];
    cell.selectedCountButton.backgroundColor = CLNumBGViewNormalColor;
    cell.model = self.albumArray[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CLAlbumModel *model = self.albumArray[indexPath.row];
    if (self.selectAlbumBlock) {
        self.selectAlbumBlock(model);
    }
    [self dismiss];
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    // iso 7
    if ([cell  respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    // ios 8
    if([cell respondsToSelector:@selector(setLayoutMargins:)]){
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismiss];
}

#pragma mark -
#pragma mark -- -- -- -- -- - Public Methond - -- -- -- -- --
- (void)showInView:(UIView *)view{
    [view addSubview:self];
    if (CLAlbumRowHeight * self.albumArray.count > self.cl_height) {
        self.tableView.scrollEnabled = YES;
        tableHeight = self.cl_height;
    }else{
        self.tableView.scrollEnabled = NO;
        tableHeight = CLAlbumRowHeight * self.albumArray.count;
    }
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.tableView.frame = CGRectMake(0, - tableHeight, self.cl_width, tableHeight);
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.frame = CGRectMake(0, 0, self.cl_width, tableHeight);
    }];
}

- (void)dismiss{
    [UIView animateWithDuration:0.15 animations:^{
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        self.tableView.frame = CGRectMake(0, - tableHeight, self.cl_width, tableHeight);
    }completion:^(BOOL finished) {
        if (self.disMissBlock) {
            self.disMissBlock();
        }
        [self removeFromSuperview];
    }];
}

- (UITableView *)setupTableView{
    if (!self.tableView) {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.backgroundColor = CLBgViewColor;
        self.tableView.tableFooterView = [[UIView alloc] init];
        [self.tableView registerClass:[CLAlbumCell class] forCellReuseIdentifier:@"CLAlbumCell"];
        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsZero];
        }
        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsZero];
        }
    }
    return self.tableView;
}

@end
