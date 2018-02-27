//
//  ViewController.m
//  Demo_1
//
//  Created by nethanhan on 2017/9/18.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import "PlaneNode.h"

@interface ViewController ()<ARSCNViewDelegate>

// AR视图
@property (nonatomic, strong) ARSCNView *scnView;
// 会话配置
@property (nonatomic, strong) ARConfiguration *sessionConfiguration;

// 遮罩视图
@property (nonatomic, strong) UIView *maskView;
// 提示标签
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation ViewController

#pragma mark - ViewCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加AR视图和界面元素
    [self.view addSubview:self.scnView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.tipLabel];
    
    // 设置AR视图代理
    self.scnView.delegate = self;
    // 显示视图的FPS信息
    self.scnView.showsStatistics = YES;
    // 显示检测到的特征点
    self.scnView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
    
    // 添加手势
    [self addGestureOfSceneView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 运行视图中自带的会话
    [self.scnView.session runWithConfiguration:self.sessionConfig];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 暂停会话
    [self.scnView.session pause];
}

#pragma mark - TapGesture

- (void)addGestureOfSceneView
{
    // 添加单击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addARGeometryFromGesture:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.scnView addGestureRecognizer:tapGesture];
}

- (void)addARGeometryFromGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    CGPoint point = [tapGestureRecognizer locationInView:self.scnView];
    
    // 命中测试，类型为已存在的平面
    NSArray<ARHitTestResult *> *resultArray = [self.scnView hitTest:point types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    if (nil!=resultArray && resultArray.count>0)
    {
        // 拿到命中测试结果，取出位置
        ARHitTestResult *result = [resultArray firstObject];
        SCNVector3 vector = [self positionWithWorldTransform:result.worldTransform];
        
        // 获取模型场景
        SCNScene *scene = [SCNScene sceneNamed:@"scene.scn"];
        SCNNode *node = [scene.rootNode clone];
        node.position = vector;
        
        // 添加到根节点中
        [self.scnView.scene.rootNode addChildNode:node];
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

- (void)session:(ARSession *)session cameraDidChangeTrackingState:(ARCamera *)camera
{
    // 判断状态
    switch (camera.trackingState)
    {
        case ARTrackingStateNotAvailable:
        {
            // 当追踪不可用时显示遮罩视图
            self.tipLabel.text = @"追踪不可用";
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.7;
            }];
        }
            break;
        case ARTrackingStateLimited:
        {
            // 当追踪有限时输出原因并显示遮罩视图
            NSString *title = @"有限的追踪，原因为";
            NSString *desc;
            // 判断原因
            switch (camera.trackingStateReason)
            {
                case ARTrackingStateReasonNone:
                {
                    desc = @"不受约束";
                }
                    break;
                case ARTrackingStateReasonInitializing:
                {
                    desc = @"正在初始化，请稍等";
                }
                    break;
                case ARTrackingStateReasonExcessiveMotion:
                {
                    desc = @"设备移动过快，请注意";
                }
                    break;
                case ARTrackingStateReasonInsufficientFeatures:
                {
                    desc = @"提取不到足够的特征点，请移动设备";
                }
                    break;
                default:
                    break;
            }
            self.tipLabel.text = [NSString stringWithFormat:@"%@%@", title, desc];
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.6;
            }];
        }
            break;
        case ARTrackingStateNormal:
        {
            // 当追踪正常时遮罩视图隐藏
            self.tipLabel.text = @"追踪正常";
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.0;
            }];
        }
            break;
        default:
            break;
    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
    // 当会话出错时输出出错信息
    switch (error.code)
    {
            // errorCode=100
        case ARErrorCodeUnsupportedConfiguration:
            self.tipLabel.text = @"当前设备不支持";
            break;
            // errorCode=101
        case ARErrorCodeSensorUnavailable:
            self.tipLabel.text = @"传感器不可用，请检查传感器";
            break;
            // errorCode=102
        case ARErrorCodeSensorFailed:
            self.tipLabel.text = @"传感器出错，请检查传感器";
            break;
            // errorCode=103
        case ARErrorCodeCameraUnauthorized:
            self.tipLabel.text = @"相机不可用，请检查相机";
            break;
            // errorCode=200
        case ARErrorCodeWorldTrackingFailed:
            self.tipLabel.text = @"追踪出错，请重置";
            break;
        default:
            break;
    }
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    self.tipLabel.text = @"会话中断";
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    self.tipLabel.text = @"会话中断结束，已重置会话";
    [self.scnView.session runWithConfiguration:self.sessionConfig options: ARSessionRunOptionResetTracking];
}


#pragma mark - lazy

- (UILabel *)tipLabel
{
    if (nil == _tipLabel)
    {
        // 创建提示信息的Label
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(0, 30, CGRectGetWidth(self.scnView.frame), 50);
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
    }
    
    return _tipLabel;
}

- (UIView *)maskView
{
    if (nil == _maskView)
    {
        // 创建遮罩视图
        _maskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _maskView.userInteractionEnabled = NO;
        _maskView.backgroundColor = [UIColor whiteColor];
        _maskView.alpha = 0.6;
    }
    
    return _maskView;
}

- (ARSCNView *)scnView
{
    if (nil == _scnView)
    {
        // 创建AR视图
        _scnView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    }
    
    return _scnView;
}

- (ARConfiguration *)sessionConfig
{
    
    if (nil == _sessionConfiguration)
    {
        // 创建会话配置
        if ([ARWorldTrackingConfiguration isSupported])
        {
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

