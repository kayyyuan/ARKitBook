//
//  MagicBallNode.m
//  Game_3
//
//  Created by nethanhan on 2017/9/21.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "MagicBallNode.h"

@implementation MagicBallNode

+ (instancetype)nodeWithSceneName:(NSString *)sceneName
{
    // 从场景中提取节点
    SCNScene *magicBallScene = [SCNScene sceneNamed:sceneName];
    SCNNode *magicBallNode = [magicBallScene.rootNode clone];
    
    // 给节点增加物理特性
    SCNPhysicsShape *shape = [SCNPhysicsShape shapeWithNode:magicBallNode options:nil];
    magicBallNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:shape];
    // 关闭重力
    magicBallNode.physicsBody.affectedByGravity = NO;
    
    // 设置类别掩码
    magicBallNode.physicsBody.categoryBitMask = 2;
    // 设置测试掩码
    magicBallNode.physicsBody.contactTestBitMask = 1;
    // 设置碰撞掩码
    magicBallNode.physicsBody.collisionBitMask = 3;
    
    return (MagicBallNode *)magicBallNode;
}

@end
