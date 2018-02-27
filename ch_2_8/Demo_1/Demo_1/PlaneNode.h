//
//  PlaneNode.h
//  Demo_1-3
//
//  Created by nethanhan on 2017/9/15.
//  Copyright © 2017年 ArWriter. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARPlaneAnchor.h>

@interface PlaneNode : SCNNode

+ (instancetype)planeNodeWithAnchor:(ARPlaneAnchor *)anchor;

- (void)updatePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor;

- (void)removePlaneNodeWithAnchor:(ARPlaneAnchor *)anchor;

@end
