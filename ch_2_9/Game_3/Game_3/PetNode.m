//
//  PetNode.m
//  Game_3
//
//  Created by nethanhan on 2017/9/21.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "PetNode.h"

@implementation PetNode

+ (instancetype)nodeWithSceneName:(NSString *)sceneName
{
    // 从场景中提取节点
    SCNScene *petScene = [SCNScene sceneNamed:sceneName];
    SCNNode *petNode = [petScene.rootNode clone];
    
    // 给节点增加物理特性
    SCNPhysicsShape *shape = [SCNPhysicsShape shapeWithNode:petNode options:nil];
    petNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:shape];
    // 关闭重力
    petNode.physicsBody.affectedByGravity = NO;
    
    // 设置类别掩码
    petNode.physicsBody.categoryBitMask =1;
    // 设置测试掩码
    petNode.physicsBody.contactTestBitMask = 2;
    // 设置碰撞掩码
    petNode.physicsBody.collisionBitMask = 3;
    
    return (PetNode *)petNode;
}

@end
