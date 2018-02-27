//
//  ViewController.m
//  Game_3
//
//  Created by nethanhan on 2017/9/21.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>
#import "MagicBallNode.h"
#import "PetNode.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<ARSCNViewDelegate, SCNPhysicsContactDelegate>

// 游戏场景视图
@property (nonatomic, strong) ARSCNView *scnView;
// 会话配置
@property (nonatomic, strong) ARConfiguration *sessionConfiguration;

// 遮罩视图
@property (nonatomic, strong) UIView *maskView;
// 提示文字标签
@property (nonatomic, strong) UILabel *tipLabel;


// 分数显示
@property (nonatomic, strong) UILabel *numLabel;
// 魔法球发射按钮
@property (nonatomic, strong) UIButton *magicBallBtn;
// 寻找宠物按钮
@property (nonatomic, strong) UIButton *findBtn;

// 音效播放
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
// 计分
@property (nonatomic, assign) NSUInteger num;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加界面元素
    [self.view addSubview:self.scnView];
    [self.view addSubview:self.maskView];
    [self.view addSubview:self.tipLabel];
    [self.view addSubview:self.magicBallBtn];
    [self.view addSubview:self.numLabel];
    [self.view addSubview:self.findBtn];
    
    // 初始化分数
    self.numLabel.text = @"0";
    self.num = 0;
    
    // 设置视图代理
    self.scnView.delegate = self;
    // 设置视图物理特性代理
    self.scnView.scene.physicsWorld.contactDelegate = self;
    
    // 显示特征点
    self.scnView.debugOptions = ARSCNDebugOptionShowFeaturePoints;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // 运行会话
    [self.scnView.session runWithConfiguration:self.sessionConfiguration];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 暂停会话
    [self.scnView.session pause];
}

- (void)playAudioWithFileName:(NSString *)fileName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // 播放音效
        NSURL *url = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"mp3"];
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        
        [self.audioPlayer play];
        
    });
}

#pragma mark - HandleNode

- (void)addPetNodeToScnView
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
    
    // 添加宠物节点
    PetNode *node = [PetNode nodeWithSceneName:@"PetScene.scn"];
    node.transform = SCNMatrix4FromMat4(transform);
    [self.scnView.scene.rootNode addChildNode:node];
}

- (void)shootMagicBallNodeToPetNode
{
    // 播放音效
    [self playAudioWithFileName:@"shootAudio"];
    
    // 提取魔法球节点
    MagicBallNode *node = [MagicBallNode nodeWithSceneName:@"MagicBallScene.scn"];
    ARFrame *currentFrame = self.scnView.session.currentFrame;
    SCNMatrix4 transform = SCNMatrix4FromMat4(currentFrame.camera.transform);
    SCNVector3 direction = SCNVector3Make(-1 * transform.m31, -1 * transform.m32, -1 * transform.m33);
    SCNVector3 position  = SCNVector3Make(transform.m41, transform.m42, transform.m43);
    
    // 节点位置初始化
    node.position = position;
    // 开始发射
    [node.physicsBody applyForce:direction impulse:true];
    [self.scnView.scene.rootNode addChildNode:node];
    
    // 6秒以后从场景中移除自己
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [node removeFromParentNode];
    });
}

- (void)removePetNodeWithAnimation:(SCNNode *)node
{
    // 播放音效
    [self playAudioWithFileName:@"successAudio"];
    
    // 增加粒子特效
    SCNParticleSystem *particleSystem = [SCNParticleSystem particleSystemNamed:@"Effects.scnp" inDirectory:nil];
    SCNNode *particleNode = [[SCNNode alloc] init];
    [particleNode addParticleSystem:particleSystem];
    
    // 初始化粒子特效节点位置
    particleNode.position = node.position;
    [self.scnView.scene.rootNode addChildNode:particleNode];
    
    // 删除宠物节点
    [node removeFromParentNode];
}

#pragma mark - SCNPhysicsContactDelegate

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact
{
    if ((contact.nodeA.physicsBody.categoryBitMask == 1) || (contact.nodeB.physicsBody.categoryBitMask == 1))
    {
        // 先删除魔法球
        [contact.nodeB removeFromParentNode];
        
        // 产生随机数，然后用随机数判断魔法球是否捕捉到宠物节点
        int randomNum = (arc4random() % 100);
        if (randomNum > 50)
        {
            // 分数增加
            self.num++;
            
            // 状态更新，并且删除宠物节点
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.tipLabel.text = @"恭喜你！捕捉成功";
                self.numLabel.text = [NSString stringWithFormat:@"%lu", self.num];
                [self removePetNodeWithAnimation:contact.nodeA];
            });
        }else
        {
            // 播放逃走音效
            [self playAudioWithFileName:@"failureAudio"];
            
            // 提示信息，并且删除宠物节点
            dispatch_async(dispatch_get_main_queue(), ^{
                self.tipLabel.text = @"对方已逃走，未捕捉成功！";
                [contact.nodeA removeFromParentNode];
            });
        }
    }
}

#pragma mark - ARSCNViewDelegate

- (NSString *)getTrackingLimitedReasonFromCamera:(ARCamera *)camera
{
    NSString *reasonStr;
    // 获取追踪状态出现质量的原因
    switch (camera.trackingStateReason)
    {
        case ARTrackingStateReasonInitializing:
            reasonStr = @"游戏正在加载，请稍等！";
            break;
        case ARTrackingStateReasonExcessiveMotion:
            reasonStr = @"太快移动设备会有可能捕捉不到哦！";
            break;
        case ARTrackingStateReasonInsufficientFeatures:
            reasonStr = @"画面有点问题，请换个角度试试！";
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
            self.tipLabel.text = @"游戏无法进行！请重新打开";
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.7;
            }];
        }
            break;
        case ARTrackingStateLimited:
        {
            // 当追踪有限时输出原因并显示遮罩视图
            self.tipLabel.text = [self getTrackingLimitedReasonFromCamera:camera];
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 1.f;
            }];
        }
            break;
        case ARTrackingStateNormal:
        {
            // 当追踪正常时隐藏遮罩视图
            self.tipLabel.text = @"游戏正常进行中";
            [UIView animateWithDuration:0.5 animations:^{
                self.maskView.alpha = 0.f;
            }];
        }
            break;
        default:
            break;
    }
}

- (void)session:(ARSession *)session didFailWithError:(NSError *)error
{
    // 判断会话出错原因
    switch (error.code)
    {
        case ARErrorCodeUnsupportedConfiguration:
            self.tipLabel.text = @"对不起，您的手机不支持此游戏!";
            break;
        case ARErrorCodeSensorUnavailable:
        case ARErrorCodeSensorFailed:
        case ARErrorCodeCameraUnauthorized:
            self.tipLabel.text = @"相机或传感器貌似有点问题，请检查!";
            break;
        case ARErrorCodeWorldTrackingFailed:
            self.tipLabel.text = @"游戏内部发生了点错误，请重新打开!";
            break;
        default:
            break;
    }
}

- (void)sessionWasInterrupted:(ARSession *)session
{
    self.tipLabel.text = @"游戏中断";
}

- (void)sessionInterruptionEnded:(ARSession *)session
{
    self.tipLabel.text = @"游戏正在恢复，请稍等！";
    
    [self.scnView.session runWithConfiguration:self.sessionConfiguration options:ARSessionRunOptionResetTracking];
}

#pragma mark - lazy

- (ARSCNView *)scnView
{
    if (nil == _scnView)
    {
        // 创建游戏场景视图
        _scnView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    }
    
    return _scnView;
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
            self.tipLabel.text = @"对不起，您的手机不支持此游戏!";
        }
    }
    return _sessionConfiguration;
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
        // 创建提示信息的标签
        _tipLabel = [[UILabel alloc] init];
        
        _tipLabel.frame = CGRectMake(20, 30, CGRectGetWidth(self.scnView.frame)-40, 50);
        _tipLabel.backgroundColor = [UIColor colorWithRed:237.f/255.f green:237.f/255.f blue:237.f/255.f alpha:0.6f];
        _tipLabel.numberOfLines = 0;
        [_tipLabel.layer setMasksToBounds:YES];
        [_tipLabel.layer setCornerRadius:CGRectGetWidth(_tipLabel.frame)/20];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor blackColor];
    }
    
    return _tipLabel;
}

- (UILabel *)numLabel
{
    if (nil == _numLabel)
    {
        _numLabel = [[UILabel alloc] init];
        _numLabel.frame = CGRectMake(20, CGRectGetHeight(self.view.frame) - 100.f, 70.f, 70.f);
        _numLabel.backgroundColor =[UIColor colorWithRed:237.f/255.f green:237.f/255.f blue:237.f/255.f alpha:0.6f];
        _numLabel.textColor = [UIColor blackColor];
        _numLabel.textAlignment = NSTextAlignmentCenter;
        _numLabel.font = [UIFont fontWithName:@"ChalkboardSE-Light" size:50];
        _numLabel.layer.masksToBounds = YES;
        _numLabel.layer.cornerRadius = 35.f;
    }
    
    return _numLabel;
}

- (UIButton *)magicBallBtn
{
    if (nil == _magicBallBtn)
    {
        _magicBallBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _magicBallBtn.frame = CGRectMake((CGRectGetWidth(self.view.frame)-100.f)/2.f, CGRectGetHeight(self.view.frame) - 150.f, 100.f, 100.f);
        [_magicBallBtn setImage:[UIImage imageNamed:@"logo"] forState:UIControlStateNormal];
        _magicBallBtn.layer.masksToBounds = YES;
        _magicBallBtn.layer.cornerRadius = 50.f;
        [_magicBallBtn addTarget:self action:@selector(shootMagicBallNodeToPetNode) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _magicBallBtn;
}

- (UIButton *)findBtn
{
    if (nil == _findBtn)
    {
        _findBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _findBtn.frame = CGRectMake(CGRectGetWidth(self.view.frame)-90.f, CGRectGetHeight(self.view.frame) - 100.f, 80.f, 80.f);
        [_findBtn setImage:[UIImage imageNamed:@"find"] forState:UIControlStateNormal];
        _findBtn.layer.masksToBounds = YES;
        _findBtn.layer.cornerRadius = 35.f;
        [_findBtn addTarget:self action:@selector(addPetNodeToScnView) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _findBtn;
}

@end
