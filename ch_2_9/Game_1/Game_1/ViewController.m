//
//  ViewController.m
//  Game_1
//
//  Created by nethanhan on 2017/9/20.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>
#import <ARKit/ARKit.h>

@interface ViewController ()<ARSKViewDelegate>

// AR游戏视图
@property (nonatomic, strong) ARSKView *gameView;
// 会话配置
@property (nonatomic, strong) ARConfiguration *sessionConfiguration;

// 遮罩视图
@property (nonatomic, strong) UIView *arMaskView;
// AR信息提示标签
@property (nonatomic, strong) UILabel *arTipLabel;
// 标识点击坐标
@property (nonatomic, strong) UIView *hitPointView;

// 数字索引，代表当前是第几个数字
@property (nonatomic, assign) NSUInteger num_index;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 初始化数字索引
    self.num_index = 1;
    
    // 添加游戏视图和界面元素
    [self.view addSubview:self.gameView];
    [self.view addSubview:self.arMaskView];
    [self.view addSubview:self.arTipLabel];
    [self.view addSubview:self.hitPointView];
    
    // 设置游戏视图代理
    self.gameView.delegate = self;
    // 显示视图的FPS信息
    self.gameView.showsFPS = YES;
    // 显示场景中节点数量
    self.gameView.showsNodeCount = YES;
    
    // 循环添加6个数字
    for (int i=0; i<6; i++)
    {
        [self addRandomNumberNodeToGameScene];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 视图即将显示时运行会话
    [self.gameView.session runWithConfiguration:self.sessionConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 视图即将消失时暂停会话
    [self.gameView.session pause];
}

- (void)addRandomNumberNodeToGameScene
{
    // x轴和y轴随机渲染角度
    float randomNum = (float)(arc4random() % 100) / 100.0;
    matrix_float4x4 rotateX = SCNMatrix4ToMat4(SCNMatrix4MakeRotation(2.0*M_PI*randomNum, 1, 0, 0));
    matrix_float4x4 rotateY = SCNMatrix4ToMat4(SCNMatrix4MakeRotation(2.0*M_PI*randomNum, 0, 1, 0));
    matrix_float4x4 rotation = matrix_multiply(rotateX, rotateY);
    
    // z轴规定距离
    matrix_float4x4 translation = matrix_identity_float4x4;
    translation.columns[3].z = -1.f - randomNum;
    
    // 生成位姿矩阵
    matrix_float4x4 transform = matrix_multiply(rotation, translation);
    
    // 创建锚点并添加到会话中
    ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
    [self.gameView.session addAnchor:anchor];
}

- (void)changeHitPointViewCenterToPoint:(CGPoint)point
{
    [self.hitPointView setCenter:point];
    
    [UIView animateWithDuration:1.f animations:^{
        
        [self.hitPointView setAlpha:1.f];
        
    } completion:^(BOOL finished) {
        
        [self.hitPointView setAlpha:0.f];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // 获取点击坐标点
    UITouch *touch = [[touches allObjects] firstObject];
    // 获取场景坐标
    CGPoint gamePoint = [touch locationInNode:self.gameView.scene];
    // 获取屏幕坐标
    CGPoint screenPoint = [touch locationInView:self.gameView];
    // 显示点击位置
    [self changeHitPointViewCenterToPoint:screenPoint];
    
    // 搜索节点
    NSArray <SKNode *>* nodes = [self.gameView.scene nodesAtPoint:gamePoint];
    SKNode *node = [nodes firstObject];
    if (node)
    {
        // 判断是不是当前的数字
        NSString *imageName = [NSString stringWithFormat:@"num_%lu", self.num_index];
        if ([imageName isEqualToString:node.name])
        {
            // 如果是当前数字，消除掉
            [node removeFromParent];
            self.arTipLabel.text = [NSString stringWithFormat:@"消除了数字%lu",self.num_index];
            
            self.num_index++;
        }
    }
}

#pragma mark - ARSKViewDelegate

- (SKNode *)view:(ARSKView *)view nodeForAnchor:(ARAnchor *)anchor
{
    // 使用数字索引拼接图片名字
    NSString *imageName = [NSString stringWithFormat:@"num_%lu", self.num_index++];
    // 根据图片创建精灵节点
    SKSpriteNode *node = [SKSpriteNode spriteNodeWithImageNamed:imageName];
    node.name = imageName;
    
    // 如果是最后一个数字，重置数字索引
    if (self.num_index==7)
    {
        self.num_index = 1;
    }
    
    return node;
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
            self.arTipLabel.text = @"追踪不可用";
            [UIView animateWithDuration:0.5 animations:^{
                self.arMaskView.alpha = 0.7;
            }];
        }
            break;
        case ARTrackingStateLimited:
        {
            // 当追踪有限时输出原因并显示遮罩视图
            NSString *title = @"有限的追踪，原因为";
            NSString *desc = [self getTrackingLimitedReasonFromCamera:camera];
            self.arTipLabel.text = [NSString stringWithFormat:@"%@%@", title, desc];
            [UIView animateWithDuration:0.5 animations:^{
                self.arMaskView.alpha = 1.f;
            }];
        }
            break;
        case ARTrackingStateNormal:
        {
            // 当追踪正常时隐藏遮罩视图
            self.arTipLabel.text = @"追踪正常";
            [UIView animateWithDuration:0.5 animations:^{
                self.arMaskView.alpha = 0.f;
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
            self.arTipLabel.text = @"当前设备不支持";
            break;
        case ARErrorCodeSensorUnavailable:
            self.arTipLabel.text = @"传感器不可用，请检查传感器";
            break;
        case ARErrorCodeSensorFailed:
            self.arTipLabel.text = @"传感器出错，请检查传感器";
            break;
        case ARErrorCodeCameraUnauthorized:
            self.arTipLabel.text = @"相机不可用，请检查相机";
            break;
        case ARErrorCodeWorldTrackingFailed:
            self.arTipLabel.text = @"追踪出错，请重置";
            break;
        default:
            break;
    }
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    self.arTipLabel.text = @"会话出现中断";
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    self.arTipLabel.text = @"会话中断结束，正在重置会话";
    [self.gameView.session runWithConfiguration:self.sessionConfiguration options: ARSessionRunOptionResetTracking];
}

#pragma mark - lazy

- (UIView *)hitPointView
{
    if (nil == _hitPointView)
    {
        _hitPointView = [[UIView alloc] init];
        _hitPointView.frame =CGRectMake(0, 0, 30, 30);
        _hitPointView.backgroundColor = [UIColor blackColor];
        _hitPointView.alpha = 0.f;
    }
    return _hitPointView;
}

- (ARSKView *)gameView
{
    if (nil == _gameView)
    {
        // 创建AR视图，需要使用2D场景
        _gameView = [[ARSKView alloc] initWithFrame:self.view.bounds];
        SKScene *scene = [SKScene nodeWithFileNamed:@"GameScene.sks"];
        [_gameView presentScene:scene];
    }
    
    return _gameView;
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
            worldConfig.planeDetection = ARPlaneDetectionNone;
            worldConfig.lightEstimationEnabled = YES;
            
            _sessionConfiguration = worldConfig;
            
        }else
        {
            // 创建可追踪3DOF的会话配置
            AROrientationTrackingConfiguration *orientationConfig = [AROrientationTrackingConfiguration new];
            _sessionConfiguration = orientationConfig;
            self.arTipLabel.text = @"当前设备不支持6DOF追踪";
        }
    }
    return _sessionConfiguration;
}

- (UIView *)arMaskView
{
    if (nil == _arMaskView)
    {
        // 创建遮罩视图
        _arMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
        _arMaskView.userInteractionEnabled = NO;
        _arMaskView.backgroundColor = [UIColor whiteColor];
        _arMaskView.alpha = 1.0;
    }
    return _arMaskView;
}

- (UILabel *)arTipLabel
{
    if (nil == _arTipLabel)
    {
        // 创建提示信息的Label
        _arTipLabel = [[UILabel alloc] init];
        _arTipLabel.frame = CGRectMake(0, 30, CGRectGetWidth(self.gameView.frame), 50);
        _arTipLabel.numberOfLines = 0;
        _arTipLabel.textColor = [UIColor blackColor];
    }
    
    return _arTipLabel;
}

@end
