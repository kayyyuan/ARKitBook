//
//  PlaneNode.h
//  Demo_1-2
//
//  Created by nethanhan on 2017/9/14.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARPlaneAnchor.h>

@interface PlaneNode : SCNNode

+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor;

- (void)updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor;

- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor;

@end
