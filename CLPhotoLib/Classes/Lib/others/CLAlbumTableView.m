//
//  CLAlbumTableView.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/2.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLAlbumTableView.h"
#import "CLPhotoCollectionCell.h"
#import "CLPhotoModel.h"
#import "CLConfig.h"
#import "CLPhotoManager.h"
#import "CLExtHeader.h"

static NSString *cellIdentifier = @"CLAlbumTableViewCellIdentifier";
@interface CLAlbumTableView ()<UITableViewDelegate, UITableViewDataSource> {
    BOOL    _isAnimated;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGFloat tableHeight;
    
@end

@implementation CLAlbumTableView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.tableView.hidden = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tableView.hidden = NO;
    }
    return self;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.tableFooterView = [UIView new];
        if (@available(iOS 11.0, *)) {
            [_tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAlways];
        }
        [self addSubview:_tableView];
    }
    return _tableView;
}

#pragma mark -
#pragma mark -- UITableViewDataSource & UITableViewDelegate --
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CLAlbumTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[CLAlbumTableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    if (_albumArray.count > indexPath.row) {
        cell.model = _albumArray[indexPath.row];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (_albumArray.count > indexPath.row) {
        if (self.didSelectAlbumBlock) {
            self.didSelectAlbumBlock(_albumArray[indexPath.row]);
        }
    }
    [self dismiss];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CLAlbumRowHeight();
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // iso 7
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    // ios 8
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self dismiss];
}

#pragma mark -
#pragma mark -- -- -- -- -- - Public Methond - -- -- -- -- --
- (void)setAlbumArray:(NSArray *)albumArray {
    _albumArray = albumArray;
    [self reloadData];
}

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)showAlbumAnimated:(BOOL)animated {
    _isAnimated = animated;
    if (_isAnimated) {
        if (CLAlbumRowHeight() * _albumArray.count > self.height*CLAlbumDropDownScale) {
            self.tableView.scrollEnabled = YES;
            _tableHeight = self.height*CLAlbumDropDownScale;
        } else {
            self.tableView.scrollEnabled = NO;
            _tableHeight = CLAlbumRowHeight() * self.albumArray.count;
        }
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.tableView.frame = CGRectMake(0, - _tableHeight, self.width, _tableHeight);
        self.hidden = NO;
        cl_weakSelf(self);
        [UIView animateWithDuration:CLAlbumDropDownAnimationTime animations:^{
            weakSelf.tableView.frame = CGRectMake(0, 0, weakSelf.width, weakSelf.tableHeight);
        }];
    } else {
        self.tableView.scrollEnabled = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_isAnimated) {
        if (CLAlbumRowHeight() * _albumArray.count > self.height*CLAlbumDropDownScale) {
            _tableHeight = self.height*CLAlbumDropDownScale;
        } else {
            _tableHeight = CLAlbumRowHeight() * self.albumArray.count;
        }
        self.tableView.frame = CGRectMake(0, 0, self.width, _tableHeight);
    } else {
        self.tableView.frame = self.bounds;
    }
}

- (void)setTableColor:(UIColor *)tableColor {
    _tableColor = tableColor;
    self.tableView.backgroundColor = _tableColor;
}

- (void)dismiss {
    if (!_isAnimated) {
        return;
    }
    cl_weakSelf(self);
    [UIView animateWithDuration:CLAlbumPackUpAnimationTime animations:^{
        weakSelf.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        weakSelf.tableView.frame = CGRectMake(0, -weakSelf.tableHeight, weakSelf.width, weakSelf.tableHeight);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        if (self.disMissAlbumBlock) {
            self.disMissAlbumBlock();
        }
    }];
}

@end
