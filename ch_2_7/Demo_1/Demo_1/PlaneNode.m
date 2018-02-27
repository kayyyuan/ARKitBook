//
//  PlaneNode.m
//  Demo_1-2
//
//  Created by nethanhan on 2017/9/14.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import "PlaneNode.h"


@interface PlaneNode()

@property (nonatomic, weak) SCNPlane *planeGeometry;

@end

@implementation PlaneNode

+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor
{
    PlaneNode *node = [[PlaneNode alloc] init];
    if (node)
    {
        // 创建平面
        SCNPlane *planeGeometry = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
        node.planeGeometry = planeGeometry;

        // 创建材质并用于平面
        SCNMaterial *material = [SCNMaterial new];
        material.diffuse.contents = [UIImage imageNamed:@"plane"];
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
    // 更新几何模型
    self.planeGeometry.width = anchor.extent.x;
    self.planeGeometry.height = anchor.extent.z;
    
    // 更新节点位置
    self.position = SCNVector3Make(anchor.center.x, -0.002, anchor.center.z);
}

- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor
{
    // 删除节点
    [self removeFromParentNode];
}

@end
