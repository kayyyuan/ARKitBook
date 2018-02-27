//
//  ViewController.m
//  Game_2
//
//  Created by nethanhan on 2017/9/20.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import "PlaneNode.h"

@interface ViewController ()<ARSCNViewDelegate>

// 场景视图
@property (nonatomic, strong) ARSCNView *sceneView;
// 会话配置
@property (nonatomic, strong) ARConfiguration *sessionConfiguration;
// 场景遮罩视图
@property (nonatomic, strong) UIView *sceneMaskView;
// 提示信息标签
@property (nonatomic, strong) UILabel *tipLabel;
// 当前操作的节点
@property (nonatomic, strong) SCNNode *currentSelectNode;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加AR视图和界面元素
    [self.view addSubview:self.sceneView];
    [self.view addSubview:self.sceneMaskView];
    [self.view addSubview:self.tipLabel];
    
    // 设置AR视图代理
    self.sceneView.delegate = self;
    // 显示视图的FPS信息
    self.sceneView.showsStatistics = YES;
    // 显示检测到的特征点
    self.sceneView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    
    [self addGestureOfScnView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 运行视图中自带的会话
    [self.sceneView.session runWithConfiguration:self.sessionConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 暂停会话
    [self.sceneView.session pause];
}

#pragma mark - Gesture

- (void)addGestureOfScnView
{
    // 添加单击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureEventFrom:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tapGesture];
    
    // 添加长按手势
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGestureEventFrom:)];
    longGesture.minimumPressDuration = 1;
    [self.sceneView addGestureRecognizer:longGesture];
    
    // 添加滑动手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureEventFrom:)];
    panGesture.maximumNumberOfTouches = 1;
    [self.sceneView addGestureRecognizer:panGesture];
    
    // 添加捏合手势
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureEventFrom:)];
    [self.sceneView addGestureRecognizer:pinchGesture];
}

- (void)tapGestureEventFrom:(UITapGestureRecognizer *)tapGestureRecognizer
{
    // 获取点击的坐标点
    CGPoint point = [tapGestureRecognizer locationInView:self.sceneView];
    
    // 进行命中测试，看是否与平面相交
    NSArray <ARHitTestResult *>* array = [self.sceneView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    ARHitTestResult *result = [array firstObject];
    if (result)
    {
        // 提取位置
        SCNVector3 vector = [self positionWithWorldTransform:result.worldTransform];
        
        // 克隆场景中的根节点
        SCNScene *scene = [SCNScene sceneNamed:@"MoonScene.scn"];
        SCNNode *node = [scene.rootNode clone];
        // 赋值位置
        node.position = vector;
        
        // 添加到当前场景中
        [self.sceneView.scene.rootNode addChildNode:node];
    }
}

- (void)longGestureEventFrom:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    // 获取长按的坐标点
    CGPoint point = [longPressGestureRecognizer locationInView:self.sceneView];
    
    // 在场景中搜索节点
    NSArray<SCNHitTestResult *> *array = [self.sceneView hitTest:point options:nil];
    SCNHitTestResult *result = [array firstObject];
    if (result && ![result.node.parentNode isKindOfClass:[PlaneNode class]] && result.node.parentNode.parentNode)
    {
        // 删除搜索到的节点
        [result.node.parentNode removeFromParentNode];
    }
}

- (void)panGestureEventFrom:(UIPanGestureRecognizer *)panGestureRecognizer
{
    // 开始移动
    if (panGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        // 提取坐标点
        CGPoint point = [panGestureRecognizer locationInView:self.sceneView];
        
        // 在场景内搜索节点
        NSArray <SCNHitTestResult *> *array = [self.sceneView hitTest:point options:nil];
        SCNHitTestResult *result = [array firstObject];
        if (result && ![result.node.parentNode isKindOfClass:[PlaneNode class]])
        {
            // 把搜索到的节点作为当前要操作的节点
            self.currentSelectNode = result.node.parentNode;
        }
    }
    
    // 正在移动
    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        // 判断当前操作的节点是否为空
        if (self.currentSelectNode)
        {
            // 提取每次移动到的坐标点
            CGPoint point = [panGestureRecognizer locationInView:self.sceneView];
            
            // 进行命中测试
            NSArray <ARHitTestResult *> *array = [self.sceneView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
            ARHitTestResult *result = [array firstObject];
            if (result)
            {
                // 提取相交位置
                SCNVector3 vector = [self positionWithWorldTransform:result.worldTransform];
                
                // 把移动的位置赋值给要操作的节点
                [self.currentSelectNode setPosition:vector];
            }
        }
    }
    
    // 结束移动
    if (panGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        // 结束移动时，置空
        self.currentSelectNode = nil;
    }
}

- (void)pinchGestureEventFrom:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    // 开始捏合
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        // 提取坐标
        CGPoint point = [pinchGestureRecognizer locationInView:self.sceneView];
        
        // 搜索节点
        NSArray <SCNHitTestResult *> *array = [self.sceneView hitTest:point options:nil];
        SCNHitTestResult *result = [array firstObject];
        
        if (result && ![result.node.parentNode isKindOfClass:[PlaneNode class]])
        {
            // 把搜索到的节点作为当前要操作的节点
            self.currentSelectNode = result.node.parentNode;
        }
    }
    
    // 正在捏合
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        // 判断当前操作的节点是否为空
        if (self.currentSelectNode)
        {
            // 根据每次捏合的比例来更新节点最新的比例
            CGFloat pinchScaleX = pinchGestureRecognizer.scale * self.currentSelectNode.scale.x;
            CGFloat pinchScaleY = pinchGestureRecognizer.scale * self.currentSelectNode.scale.y;
            CGFloat pinchScaleZ = pinchGestureRecognizer.scale * self.currentSelectNode.scale.z;
            
            SCNVector3 vector = SCNVector3Make(pinchScaleX, pinchScaleY, pinchScaleZ);
            
            // 设置最新的比例给节点
            [self.currentSelectNode setScale:vector];
        }
        
        pinchGestureRecognizer.scale = 1.f;
    }
    
    // 结束捏合
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        // 结束捏合时，置空
        self.currentSelectNode = nil;
    }
}

#pragma mark - Utils

- (SCNVector3)positionWithWorldTransform:(matrix_float4x4)worldTransform
{
    // 从世界坐标系中的一个位姿中提取位置
    return SCNVector3Make(worldTransform.columns[3].x, worldTransform.columns[3].y, worldTransform.columns[3].z);
}

#pragma mark - ARSCNViewDelegate

- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor
{
    // 判断场景内添加的锚点是否为平面锚点
    if ([anchor isKindOfClass:[ARPlaneAnchor class]])
    {
        // 如果是平面锚点，则自定义节点加入平面图片
        PlaneNode *node = [PlaneNode planeNodeWithAnchor:(ARPlaneAnchor*)anchor];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tipLabel.text = @"检测到平面并已添加到场景中";
        });
        
        return node;
    }
    
    return nil;
}

- (void)renderer:(id<SCNSceneRenderer>)renderer willUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    // 判断场景内更新的锚点是否为平面锚点
    if ([anchor isKindOfClass:[ARPlaneAnchor class]])
    {
        // 如果是平面锚点，则更新节点
        [(PlaneNode *)node updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor];
    }
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    // 判断场景内删除的锚点是否为平面锚点
    if ([anchor isKindOfClass:[ARPlaneAnchor class]])
    {
        // 如果是平面锚点，则删除节点
        [(PlaneNode *)node removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor];
    }
}

- (NSString *)getTrackingLimitedReasonFromCamera:(ARCamera *)camera
{
    NSString *reasonStr;
    // 获取追踪状态出现质量的原因
    switch (camera.trackingStateReason)
    {
        case ARTrackingStateReasonNone:
            reasonStr = @"不受约束";
            break;
        case ARTrackingStateReasonInitializing:
            reasonStr = @"正在初始化，请稍等";
            break;
        case ARTrackingStateReasonExcessiveMotion:
            reasonStr = @"设备移动过快，请注意";
            break;
        case ARTrackingStateReasonInsufficientFeatures:
            reasonStr = @"提取不到足够的特征点，请移动设备";
            break;
        default:
            break;
    }
    
    return reasonStr;
}

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera
{
    // 获取追踪状态
    switch (camera.trackingState)
    {
        case ARTrackingStateNotAvailable:
        {
            // 当追踪不可用时显示遮罩视图
            self.tipLabel.text = @"追踪不可用";
            [UIView animateWithDuration:0.5 animations:^{
                self.sceneMaskView.alpha = 0.7;
            }];
        }
            break;
        case ARTrackingStateLimited:
        {
            // 当追踪有限时输出原因并显示遮罩视图
            NSString *title = @"有限的追踪，原因为";
            NSString *desc = [self getTrackingLimitedReasonFromCamera:camera];
            self.tipLabel.text = [NSString stringWithFormat:@"%@%@", title, desc];
            [UIView animateWithDuration:0.5 animations:^{
                self.sceneMaskView.alpha = 1.f;
            }];
        }
            break;
        case ARTrackingStateNormal:
        {
            // 当追踪正常时隐藏遮罩视图
            self.tipLabel.text = @"追踪正常";
            [UIView animateWithDuration:0.5 animations:^{
                self.sceneMaskView.alpha = 0.f;
            }];
        }
            break;
        default:
            break;
    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
    // 当会话出错时输出错误信息
    switch (error.code)
    {
        case ARErrorCodeUnsupportedConfiguration:
            self.tipLabel.text = @"当前设备不支持";
            break;
        case ARErrorCodeSensorUnavailable:
            self.tipLabel.text = @"传感器不可用，请检查传感器";
            break;
        case ARErrorCodeSensorFailed:
            self.tipLabel.text = @"传感器出错，请检查传感器";
            break;
        case ARErrorCodeCameraUnauthorized:
            self.tipLabel.text = @"相机不可用，请检查相机";
            break;
        case ARErrorCodeWorldTrackingFailed:
            self.tipLabel.text = @"追踪出错，请重置";
            break;
        default:
            break;
    }
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    self.tipLabel.text = @"会话出现中断";
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    self.tipLabel.text = @"会话中断结束，正在重置会话";
    [self.sceneView.session runWithConfiguration:self.sessionConfiguration options: ARSessionRunOptionResetTracking];
}

#pragma mark - lazy

- (UILabel *)tipLabel
{
    if (nil == _tipLabel)
    {
        // 创建提示信息的Label
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(0, 30, CGRectGetWidth(self.sceneView.frame), 50);
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor orangeColor];
    }
    
    return _tipLabel;
}

- (UIView *)sceneMaskView
{
    if (nil == _sceneMaskView)
    {
        // 创建遮罩视图
        _sceneMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _sceneMaskView.userInteractionEnabled = NO;
        _sceneMaskView.backgroundColor = [UIColor whiteColor];
        _sceneMaskView.alpha = 0.6;
    }
    
    return _sceneMaskView;
}

- (ARSCNView *)sceneView
{
    if (nil == _sceneView)
    {
        // 创建AR视图
        _sceneView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    }
    
    return _sceneView;
}

- (ARConfiguration *)sessionConfiguration
{
    if (nil == _sessionConfiguration)
    {
        // 创建会话配置
        if ([ARWorldTrackingConfiguration isSupported])
        {
            // 创建可追踪6DOF的会话配置
            ARWorldTrackingConfiguration *worldConfig = [ARWorldTrackingConfiguration new];
            worldConfig.planeDetection = ARPlaneDetectionHorizontal;
            worldConfig.lightEstimationEnabled = YES;
            
            _sessionConfiguration = worldConfig;
            
        }else
        {
            // 创建可追踪3DOF的会话配置
            AROrientationTrackingConfiguration *orientationConfig = [AROrientationTrackingConfiguration new];
            _sessionConfiguration = orientationConfig;
            self.tipLabel.text = @"当前设备不支持6DOF追踪";
        }
    }
    return _sessionConfiguration;
}

@end
