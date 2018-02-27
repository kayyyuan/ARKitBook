//
//  PlaneNode.m
//  Demo_1-3
//
//  Created by nethanhan on 2017/9/15.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "PlaneNode.h"

@implementation PlaneNode

+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor
{
    PlaneNode *node = [[PlaneNode alloc] init];
    if (node)
    {
        // 创建材质并用于平面
        SCNMaterial *material = [SCNMaterial new];
        material.diffuse.contents = [UIImage imageNamed:@"plane"];
        
        // 创建平面
        SCNPlane *planeGeometry = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
        planeGeometry.materials = @[material];
        
        // 创建节点并作为当前节点的子节点
        SCNNode *childNode = [SCNNode nodeWithGeometry:planeGeometry];
        childNode.position = SCNVector3Make(anchor.center.x, -0.002, anchor.center.z);
        childNode.transform = SCNMatrix4MakeRotation(-M_PI/2.0, 1.0, 0.0, 0.0);
        [node addChildNode:childNode];
    }
    
    return node;
}

- (void)updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor
{
    // 更新平面的范围
    SCNNode *node = self.childNodes.firstObject;
    SCNPlane *planeGeometry = (SCNPlane *)node.geometry;
    
    planeGeometry.width = anchor.extent.x;
    planeGeometry.height = anchor.extent.z;
    
    // 更新节点位置
    node.position = SCNVector3Make(anchor.center.x, -0.002, anchor.center.z);
}

- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor
{
    // 删除节点
    [self removeFromParentNode];
}

@end
