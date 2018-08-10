//
//  CLEditVideoController.m
//  CLPhotoLib
//
//  Created by ClaudeLi on 2017/11/15.
//  Copyright © 2017年 ClaudeLi. All rights reserved.
//

#import "CLEditVideoController.h"
#import "CLConfig.h"
#import "CLExtHeader.h"

static CGFloat  videoBottomSpacing  = 25.0f;
static CGFloat  cancelTopSpacing    = 15.0f;
static CGFloat  editSideMargin      = 20.0f;
static CGFloat  imageItemHeight     = 50.0f;

static NSString *itemIdentifier = @"CLEditCollectionCellIdentifier";

@interface CLEditCollectionCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation CLEditCollectionCell

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = self.bounds;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
}

@end

#pragma mark -
#pragma mark -
#pragma mark -- CLEditFrameView --

/*
struct CLRatio {
    CGFloat startRatio;
    CGFloat endRatio;
};
typedef struct CG_BOXABLE CLRatio CLRatio;

CG_INLINE CLRatio
CLRatioMake(CGFloat start, CGFloat end){
    CLRatio rat;
    rat.startRatio = start;
    rat.endRatio = end;
    return rat;
}
*/

@protocol CLEditFrameViewDelegate <NSObject>

- (void)editValidDurationChanging:(BOOL)isRight;

- (void)editValidDurationEndChanged;

@end

@interface CLEditFrameView : UIView{
    UIImageView *_leftView;
    UIImageView *_rightView;
    UIView      *_layerView;
    CGFloat     _minSpacing;
}

@property (nonatomic, assign, readonly) CGFloat startRatio;
@property (nonatomic, assign, readonly) CGFloat endRatio;

@property (nonatomic, assign) CGFloat minRatio;
@property (nonatomic, assign) CGRect  validRect;
@property (nonatomic, weak) id<CLEditFrameViewDelegate> delegate;

@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation CLEditFrameView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (CGFloat)startRatio{
    return (_validRect.origin.x - editSideMargin)/(_layerView.width * 1.0);
}

- (CGFloat)endRatio{
    return (_validRect.origin.x + _validRect.size.width - editSideMargin)/(_layerView.width * 1.0);
}

- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    self.validRect = CGRectMake(editSideMargin, 0, self.width - 2 * editSideMargin, self.height);
    _layerView.frame = self.validRect;
    _minSpacing = _minRatio*_layerView.width;
}

- (void)setValidRect:(CGRect)validRect{
    _validRect = validRect;
    _leftView.frame = CGRectMake(validRect.origin.x - self.height*0.3, 0, self.height*0.6, self.height);
    _rightView.frame = CGRectMake(validRect.origin.x - self.height*0.3 + _validRect.size.width, _leftView.top, _leftView.width, _leftView.height);
    [self setNeedsDisplay];
}

- (void)setupUI{
    _minRatio = 0.1;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    _layerView = [[UIView alloc] init];
    _layerView.layer.borderWidth = 2;
    _layerView.layer.borderColor = [UIColor clearColor].CGColor;;
    [self addSubview:_layerView];
    
    _leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromBundle:@"clicon_edit_left"]];
    _leftView.userInteractionEnabled = YES;
    _leftView.contentMode = UIViewContentModeScaleAspectFit;
    _leftView.tag = 99;
    UIPanGestureRecognizer *lg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_leftView addGestureRecognizer:lg];
    [self addSubview:_leftView];
    
    _rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromBundle:@"clicon_edit_right"]];
    _rightView.userInteractionEnabled = YES;
    _rightView.contentMode = UIViewContentModeScaleAspectFit;
    _rightView.tag = 100;
    UIPanGestureRecognizer *rg = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_rightView addGestureRecognizer:rg];
    [self addSubview:_rightView];
}

- (void)panAction:(UIGestureRecognizer *)pan{
    _layerView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:.3].CGColor;
    CGPoint point = [pan locationInView:self];
    
    CGRect rct = self.validRect;
    
    const CGFloat W = _layerView.right;
    CGFloat minX = _layerView.left;
    CGFloat maxX = W;
    BOOL isRight = NO;
    switch (pan.view.tag) {
        case 99: {
            //left
            maxX = rct.origin.x + rct.size.width - _minSpacing;
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            rct.size.width -= (point.x - rct.origin.x);
            rct.origin.x = point.x;
        }
            break;
            
        case 100:
        {
            //right
            isRight = YES;
            minX = rct.origin.x + _minSpacing;
            point.x = MAX(minX, MIN(point.x, maxX));
            point.y = 0;
            rct.size.width = (point.x - rct.origin.x);
        }
            break;
    }
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(editValidDurationChanging:)]) {
                [self.delegate editValidDurationChanging:isRight];
            }
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
        {
            _layerView.layer.borderColor = [UIColor clearColor].CGColor;
            if (self.delegate && [self.delegate respondsToSelector:@selector(editValidDurationEndChanged)]) {
                [self.delegate editValidDurationEndChanged];
            }
        }
            break;
            
        default:
            break;
    }
    self.validRect = rct;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(_leftView.frame, point)) {
        if (CGRectContainsPoint(_rightView.frame, point)) {
            CGPoint lp = [self convertPoint:point toView:_leftView];
            if (lp.x > _leftView.width/2.0) {
                return _rightView;
            }
        }
        return _leftView;
    }
    if (CGRectContainsPoint(_rightView.frame, point)) {
        return _rightView;
    }
    return nil;
}

- (void)drawRect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context, _validRect);
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 4.0);
    
    CGPoint topPoints[2];
    topPoints[0] = CGPointMake(_validRect.origin.x, 0);
    topPoints[1] = CGPointMake(_validRect.origin.x+_validRect.size.width, 0);
    
    CGPoint bottomPoints[2];
    bottomPoints[0] = CGPointMake(_validRect.origin.x, _validRect.size.height);
    bottomPoints[1] = CGPointMake(_validRect.origin.x+_validRect.size.width, _validRect.size.height);
    
    CGContextAddLines(context, topPoints, 2);
    CGContextAddLines(context, bottomPoints, 2);
    
    CGContextDrawPath(context, kCGPathStroke);
}

@end

#pragma mark -
#pragma mark -
#pragma mark -- CLEditVideoController --

@interface CLEditVideoController ()<UICollectionViewDelegate, UICollectionViewDataSource, CLEditFrameViewDelegate>{
    UICollectionViewFlowLayout *_layout;
    NSTimeInterval  _interval;
    NSInteger       _imageCount;
    NSTimeInterval  _maxValidTime;
    NSTimer        *_timer;
    BOOL            _canRotate;
    NSInteger       _degrees;
}

@property (nonatomic, strong) AVAsset          *asset;
@property (nonatomic, strong) AVPlayerLayer    *playerLayer;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) CLEditFrameView  *editView;
@property (nonatomic, strong) NSMutableArray   *imageArray;

@property (nonatomic, strong) UILabel   *timeLabel;
@property (nonatomic, strong) UIView    *progressView;

@property (nonatomic, strong) UIButton *rotateBtn;

@property (nonatomic, strong) UIButton  *cancelBtn;
@property (nonatomic, strong) UIButton  *doneBtn;

@end

@implementation CLEditVideoController

#pragma mark -
#pragma mark -- Lazy Loads --
- (CLPickerRootController *)picker{
    return (CLPickerRootController *)self.navigationController;
}

- (NSMutableArray *)imageArray{
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    }
    return _imageArray;
}

- (UICollectionView *)collectionView{
    if (!_collectionView) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:_layout];
        _collectionView.backgroundColor = [UIColor blackColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        //设置滑动速度
        //        UIScrollViewDecelerationRateNormal
        _collectionView.decelerationRate = 0;
        [_collectionView registerClass:[CLEditCollectionCell class] forCellWithReuseIdentifier:itemIdentifier];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

- (CLEditFrameView *)editView{
    if (!_editView) {
        _editView = [[CLEditFrameView alloc] init];
        _editView.delegate = self;
    }
    return _editView;
}

- (UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:14];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (UIView *)progressView{
    if (!_progressView) {
        _progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, imageItemHeight)];
        _progressView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.7];
        [self.editView addSubview:_progressView];
    }
    return _progressView;
}

- (UIButton *)rotateBtn{
    if (!_rotateBtn) {
        _rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rotateBtn setTitle:CLString(@"旋转") forState:UIControlStateNormal];
        [_rotateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _rotateBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _rotateBtn.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
        [_rotateBtn addTarget:self action:@selector(clickRotateBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rotateBtn;
}

- (UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:CLString(@"CLText_Cancel") forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
        [_cancelBtn addTarget:self action:@selector(clickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)doneBtn{
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_doneBtn setTitle:CLString(@"CLText_Done") forState:UIControlStateNormal];
        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _doneBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
        _doneBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:CLNavigationItemFontSize];
        [_doneBtn addTarget:self action:@selector(clickDoneBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}

#pragma mark -
#pragma mark -- Life Cycle Methods --
- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    self.view.backgroundColor = [UIColor blackColor];
    
    [self _initValue];
    [self _initUI];
    [self _initData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarHidden = YES;
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarHidden = NO;
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    UIEdgeInsets inset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        inset = self.view.safeAreaInsets;
    }
    CGFloat itemWidth = (self.view.width - editSideMargin * 2 - inset.left - inset.right)/10.0;
    _layout.itemSize = CGSizeMake(itemWidth, imageItemHeight);
    _layout.sectionInset = UIEdgeInsetsMake(0, editSideMargin + inset.left, 0, editSideMargin + inset.right);
    [_collectionView setCollectionViewLayout:_layout];
    
    _playerLayer.frame = CGRectMake(inset.left, inset.top, self.view.width - inset.left - inset.right, self.view.height - inset.top - inset.bottom - CLToolBarHeight - cancelTopSpacing - imageItemHeight - videoBottomSpacing);
    
    _timeLabel.frame = CGRectMake(inset.left, CGRectGetMaxY(_playerLayer.frame), self.view.width - inset.left - inset.right, videoBottomSpacing);
    _collectionView.frame = CGRectMake(inset.left, _timeLabel.bottom, self.view.width - inset.left - inset.right, imageItemHeight);
    _editView.frame = _collectionView.frame;
    _cancelBtn.frame = CGRectMake(inset.left + 15, _collectionView.bottom + cancelTopSpacing, 70, CLToolBarHeight);
    _doneBtn.frame = CGRectMake(self.view.width - inset.right - 15 - 70, _cancelBtn.top, 70, _cancelBtn.height);
    _rotateBtn.frame = CGRectMake(0, 0, 70, _cancelBtn.height);
    _rotateBtn.center = CGPointMake(self.view.center.x, _cancelBtn.center.y);
}

- (void)_initValue{
    _canRotate = self.picker.allowAutorotate;
    // 获取时间间隔、图片个数
    if (self.model.duration > self.picker.maxDuration) {
        _interval = self.picker.maxDuration / 10.0f;
        _maxValidTime = self.picker.maxDuration;
        self.editView.minRatio = self.picker.minDuration/(self.picker.maxDuration * 1.0);
        self.timeLabel.text = [CLPhotoModel timeWithFormat:self.picker.maxDuration];
    }else{
        _interval = self.model.duration / 10.f;
        _maxValidTime = self.model.duration;
        if (self.picker.minDuration && self.model.duration >= self.picker.minDuration) {
            self.editView.minRatio = self.picker.minDuration/(self.model.duration * 1.0);
        }
        self.timeLabel.text = self.model.timeFormat;
    }
    _imageCount = round(self.model.duration/_interval);
}

- (void)_initUI{
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.cancelBtn];
    [self.view addSubview:self.doneBtn];
    [self.view addSubview:self.editView];
//    [self.view addSubview:self.rotateBtn];
}

- (void)_initData{
    self.playerLayer = [[AVPlayerLayer alloc] init];
//    self.playerLayer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor;
//    self.playerLayer.borderWidth = 1.0f;
    [self.view.layer addSublayer:_playerLayer];
    
    cl_weakSelf(self);
    [CLPhotoShareManager requestVideoAssetForAsset:self.model.asset completion:^(AVAsset *asset, NSDictionary *info) {
        cl_strongSelf(weakSelf);
        if (!strongSelf) {
            return;
        }
        if (!asset) return;
        strongSelf.asset = asset;
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:strongSelf.asset];
        if (!playerItem) return;
        [strongSelf requestThumbnailImages];
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.playerLayer.player = [AVPlayer playerWithPlayerItem:playerItem];
            [strongSelf.playerLayer.player play];
            [strongSelf startTimer];
        });
    }];
}

- (void)requestThumbnailImages{
    cl_weakSelf(self);
    [CLEditManager requestThumbnailImagesForAVAsset:self.asset interval:_interval size:CGSizeMake(self.model.asset.pixelWidth, imageItemHeight * [UIScreen mainScreen].scale) eachThumbnail:^(UIImage *image) {
        if (image) {
            cl_strongSelf(weakSelf);
            if (strongSelf) {
                [strongSelf.imageArray addObject:image];
                if (strongSelf.imageArray.count <= strongSelf->_imageCount) {
                    [strongSelf.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:strongSelf.imageArray.count - 1 inSection:0]]];
                }
            }
        }
    } complete:^(AVAsset *asset, NSArray<UIImage *> *images) {
        cl_strongSelf(weakSelf);
        if (strongSelf) {
            strongSelf->_imageCount = images.count;
            [strongSelf.collectionView reloadData];
        }
    }];
}

#pragma mark -
#pragma mark -- UICollectionViewDataSource & UICollectionViewDelegate --
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _imageCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CLEditCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:itemIdentifier forIndexPath:indexPath];
    if (indexPath.row < _imageArray.count) {
        cell.imageView.image = _imageArray[indexPath.row];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.playerLayer.player) {
        return;
    }
    [self stopTimer];
    [self.playerLayer.player pause];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self startTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self startTimer];
}

#pragma mark -
#pragma mark -- CLEditFrameViewDelegate --
- (void)editValidDurationChanging:(BOOL)isRight{
    if (_canRotate) {
        self.picker.allowAutorotate = NO;
    }
    [self stopTimer];
    [self.playerLayer.player pause];
    if (isRight) {
        [self.playerLayer.player seekToTime:[self getEndTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }else{
        [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    self.timeLabel.text = [CLPhotoModel timeWithFormat:(_editView.endRatio - _editView.startRatio)*_maxValidTime];
}

- (void)editValidDurationEndChanged{
    if (_canRotate) {
        self.picker.allowAutorotate = YES;
    }
    [self startTimer];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition: ^(id<UIViewControllerTransitionCoordinatorContext> context){
     } completion: ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         if (self.playerLayer.player.currentItem) {
             [self startTimer];
             self.timeLabel.text = [CLPhotoModel timeWithFormat:(_editView.endRatio - _editView.startRatio)*_maxValidTime];
         }
     }];
}

#pragma mark -
#pragma mark -- Notification --
- (void)enterBackground{
    [self stopTimer];
}

- (void)enterForeground{
    [self startTimer];
}

#pragma mark -
#pragma mark -- Private Methods --
- (void)startTimer{
    if (!self.playerLayer.player.currentItem) {
        return;
    }
    if (_timer) {
        [self stopTimer];
    }
    CGFloat duration = _interval * self.editView.validRect.size.width / _layout.itemSize.width;
    _timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(playPartVideo:) userInfo:nil repeats:YES];
    [_timer fire];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    self.progressView.frame = CGRectMake(self.editView.validRect.origin.x, 0, 2, imageItemHeight);
    cl_weakSelf(self);
    [UIView animateWithDuration:duration delay:.0 options:UIViewAnimationOptionRepeat|UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear animations:^{
        cl_strongSelf(weakSelf);
        if (strongSelf) {
            strongSelf.progressView.frame = CGRectMake(CGRectGetMaxX(self.editView.validRect)-2, 0, 2, imageItemHeight);
        }
    } completion:nil];
}

- (void)stopTimer{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (_progressView) {
        [_progressView.layer removeAllAnimations];
        [_progressView removeFromSuperview];
        _progressView = nil;
    }
}

- (CMTime)getStartTime{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat s = MAX(0, _interval * (rect.origin.x - editSideMargin)/_layout.itemSize.width);
    return CMTimeMakeWithSeconds(s, self.playerLayer.player.currentTime.timescale);
}

- (CMTime)getEndTime{
    CGRect rect = [self.collectionView convertRect:self.editView.validRect fromView:self.editView];
    CGFloat d = floorf(_interval * (rect.origin.x + self.editView.validRect.size.width - editSideMargin)/_layout.itemSize.width * 100.0)/100.0;
    return CMTimeMakeWithSeconds(d, self.playerLayer.player.currentTime.timescale);
}

- (CMTimeRange)getTimeRange{
    CMTime start = [self getStartTime];
    CGFloat d = floorf(_interval * self.editView.validRect.size.width/_layout.itemSize.width * 100.0)/100.0;
    CMTime duration = CMTimeMakeWithSeconds(d, self.playerLayer.player.currentTime.timescale);
    return CMTimeRangeMake(start, duration);
}

- (void)playPartVideo:(NSTimer *)timer{
    [self.playerLayer.player play];
    [self.playerLayer.player seekToTime:[self getStartTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#pragma mark -
#pragma mark -- Target Methods --
- (void)clickRotateBtn:(UIButton *)sender{
    _degrees+=90;
    _degrees = _degrees % 360;
    [_playerLayer setTransform:CATransform3DMakeRotation(M_PI*_degrees/180.0, 0, 0, 1)];
}

- (void)clickCancelBtn:(UIButton *)sender{
    [self.picker cancelExport];
    [self stopTimer];
    self.picker.allowAutorotate = _canRotate;
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
    [self.navigationController popViewControllerAnimated:NO];
}

- (void)clickDoneBtn:(UIButton *)sender{
    if (_asset) {
        if (_canRotate) {
            self.picker.allowAutorotate = NO;
        }
        [self stopTimer];
        [self.playerLayer.player pause];
        [self.picker showProgressWithText:[NSString stringWithFormat:@"%@..", CLString(@"CLText_Processing")]];
        
        [self.picker clickPickingVideoActionForAsset:_asset
                                               range:[self getTimeRange]
                                             degrees:_degrees];
    }
}

- (void)dealloc{
    [CLEditManager cancelAllCGImageGeneration];
    [self stopTimer];
    if (_playerLayer.player){
        [_playerLayer.player pause];
        _playerLayer.player = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CLLog(@"%s", __func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
