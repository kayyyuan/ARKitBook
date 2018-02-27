//
//  ViewController.m
//  MetalDemo
//
//  Created by nethanhan on 2017/8/23.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "ViewController.h"
#import "Renderer.h"

@interface MTKView () <RenderDestinationProvider>

@end

@interface ViewController () <MTKViewDelegate, ARSessionDelegate>

//声明会话和渲染器
@property (nonatomic, strong) ARSession *session;
@property (nonatomic, strong) Renderer *renderer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad");
    
    // 创建ARSession会话并设置代理
    self.session = [ARSession new];
    self.session.delegate = self;

    // 设置当前视图为Metal视图
    MTKView *view = (MTKView *)self.view;
    // 设置Metal视图使用系统默认的Metal设备
    view.device = MTLCreateSystemDefaultDevice();
    // 设置Metal视图的背景颜色和代理
    view.backgroundColor = UIColor.clearColor;
    view.delegate = self;
    
    // 如果当前设备不支持Metal，这里就会提前结束程序
    if(!view.device)
    {
        NSLog(@"Metal is not supported on this device");
        return;
    }
    
    // 设置渲染器以将其绘制到视图中
    self.renderer = [[Renderer alloc] initWithSession:self.session metalDevice:view.device renderDestinationProvider:view];
    
    // 设置渲染器渲染大小
    [self.renderer drawRectResized:view.bounds.size];
    
    // 向Metal视图添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObjectsFromArray:view.gestureRecognizers];
    view.gestureRecognizers = gestureRecognizers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // 创建会话配置对象
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    
    NSLog(@"会话运行前");
    
    // 运行新建的会话
    [self.session runWithConfiguration:configuration];
    
    NSLog(@"会话运行后");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 停止运行会话
    [self.session pause];
}

- (void)handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // 从会话中获取点击屏幕时输出的那一帧
    ARFrame *currentFrame = [self.session currentFrame];
    
    // 使用摄像头当前的位置创建一个锚点
    if (currentFrame)
    {
        // 创建一个向摄像头前方平移0.2米距离的转换
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = -0.2;
        // 使用当前帧中摄像头的位置进行转换，转换后得到一个矩阵
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
        
        // 新建一个锚点并添加到会话中
        ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
        [self.session addAnchor:anchor];
    }
}

#pragma mark - MTKViewDelegate

// 每当视图改变方向或布局时，就会调用这个代理方法
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [self.renderer drawRectResized:view.bounds.size];
}

// 在视图需要渲染时调用
- (void)drawInMTKView:(nonnull MTKView *)view
{
    // 渲染器更新渲染
    [self.renderer update];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSessionDelegate

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
