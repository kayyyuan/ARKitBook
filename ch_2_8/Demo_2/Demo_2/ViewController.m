//
//  ViewController.m
//  Demo_2
//
//  Created by nethanhan on 2017/9/19.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <SpriteKit/SpriteKit.h>

@interface ViewController ()<ARSKViewDelegate>

// AR视图
@property (nonatomic, strong) ARSKView *skView;
// 会话配置
@property (nonatomic, strong) ARConfiguration *sessionConfiguration;

// 遮罩视图
@property (nonatomic, strong) UIView *maskView;
// 提示标签
@property (nonatomic, strong) UILabel *tipLabel;
// 标识点击坐标
@property (nonatomic, strong) UIView *hitPointView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加AR视图和界面元素
    [self.view addSubview:self.skView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.tipLabel];
    [self.view addSubview:self.hitPointView];
    
    // 设置AR视图代理
    self.skView.delegate = self;
    // 显示视图的FPS信息
    self.skView.showsFPS = YES;
    // 显示场景中节点数量
    self.skView.showsNodeCount = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 运行视图中自带的会话
    [self.skView.session runWithConfiguration:self.sessionConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 暂停会话
    [self.skView.session pause];
}

- (void)changeHitPointViewCenterToPoint:(CGPoint)point
{
    [self.hitPointView setCenter:point];
    
    [UIView animateWithDuration:1.5f animations:^{
        
        [self.hitPointView setAlpha:1.f];
        
    } completion:^(BOOL finished) {
        
        [self.hitPointView setAlpha:0.f];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] firstObject];
    // 获取场景坐标
    CGPoint skPoint = [touch locationInNode:self.skView.scene];
    // 获取屏幕坐标
    CGPoint screenPoint = [touch locationInView:self.skView];
    // 显示点击位置
    [self changeHitPointViewCenterToPoint:screenPoint];
    
    // 搜索节点
    NSArray <SKNode *>* nodes = [self.skView.scene nodesAtPoint:skPoint];
    SKNode *node = nodes.firstObject;
    if (node)
    {
        // 如果能搜索到，则移除
        [node removeFromParent];
    }else
    {
        // 搜索不到时，添加一个节点到场景中
        ARFrame *currentFrame = self.skView.session.currentFrame;
        
        if (currentFrame)
        {
            // 使用相机的位姿信息来确定节点的位姿
            matrix_float4x4 translation = matrix_identity_float4x4;
            translation.columns[3].z  = -0.3;
            
            matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
            
            // 新建锚点添加到场景中
            ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
            [self.skView.session addAnchor:anchor];
        }
    }
}

#pragma mark - ARSKViewDelegate

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
    [self.skView.session runWithConfiguration:self.sessionConfiguration options: ARSessionRunOptionResetTracking];
}

- (SKNode *)view:(ARSKView *)view nodeForAnchor:(ARAnchor *)anchor
{
    // 会话中有锚点添加时，在这里自定义相对应的节点并返回
    SKLabelNode *node = [SKLabelNode labelNodeWithText:@"🐱"];
    node.fontSize = 20;
    
    return node;
}


#pragma mark - lazy

- (UIView *)hitPointView
{
    if (nil == _hitPointView)
    {
        _hitPointView = [[UIView alloc] init];
        _hitPointView.frame =CGRectMake(0, 0, 30, 30);
        _hitPointView.backgroundColor = [UIColor blueColor];
        _hitPointView.alpha = 0.f;
    }
    
    return _hitPointView;
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

- (UILabel *)tipLabel
{
    if (nil == _tipLabel)
    {
        // 创建提示信息的Label
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(0, 30, CGRectGetWidth(self.skView.frame), 50);
        _tipLabel.numberOfLines = 0;
        _tipLabel.textColor = [UIColor blackColor];
    }
    
    return _tipLabel;
}

- (ARSKView *)skView
{
    if (nil == _skView)
    {
        // 创建AR视图，需要使用2D场景
        _skView = [[ARSKView alloc] initWithFrame:self.view.bounds];
        
        // 通过.sks文件创建
        //SKScene *scene = [SKScene nodeWithFileNamed:@"SkScene"];
        
        // 通过代码创建
        SKScene *scene = [[SKScene alloc] initWithSize:self.view.frame.size];
        [_skView presentScene:scene];
    }
    
    return _skView;
}

- (ARConfiguration *)sessionConfiguration
{
    
    if (nil == _sessionConfiguration)
    {
        // 创建会话配置
        if ([ARWorldTrackingConfiguration isSupported])
        {
            ARWorldTrackingConfiguration *worldConfig = [ARWorldTrackingConfiguration new];
            worldConfig.planeDetection = ARPlaneDetectionNone;
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
