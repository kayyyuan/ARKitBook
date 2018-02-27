//
//  Scene.m
//  SpriteKitDemo
//
//  Created by nethanhan on 2017/8/22.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "Scene.h"

@implementation Scene

- (void)didMoveToView:(SKView *)view
{
    // Setup your scene here
}

- (void)update:(CFTimeInterval)currentTime
{
    // Called before each frame is rendered
}

//点击屏幕会执行这个方法
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //判断当前场景中的视图是否为AR视图
    if (![self.view isKindOfClass:[ARSKView class]])
    {
        return;
    }
    
    ARSKView *sceneView = (ARSKView *)self.view;
    // 从会话中获取点击屏幕时输出的那一帧
    ARFrame *currentFrame = [sceneView.session currentFrame];
    
    //使用摄像头当前的位置创建一个锚点
    if (currentFrame)
    {
        
        //创建一个向摄像头前方平移0.2米距离的转换
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = -0.2;
        //使用当前帧中摄像头的位置进行转换，转换后得到一个矩阵
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
        
        // 新建一个锚点并添加到会话中
        ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
        [sceneView.session addAnchor:anchor];
    }
}

@end
