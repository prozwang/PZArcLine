//
//  MKMapView+LayerPath.h
//  PZArchLine
//
//  Created by Proz wang on 2020/4/1.
//  Copyright © 2020 Proz wang. All rights reserved.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MKMapView (LayerPath)<CAAnimationDelegate>

@property (nonatomic, assign) BOOL isLoopAnimation;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;
@property (nonatomic, assign) CGPoint circlePoint;
@property (nonatomic, assign) double startArc;
@property (nonatomic, assign) double endArc;
@property (nonatomic, assign) BOOL isClock;
@property (nonatomic, assign) double radius;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAShapeLayer *arcLayer;
@property (nonatomic, strong) NSMutableDictionary *dispatchCache;

- (void)drawStraightLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;
- (void)drawAnimationWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint;

- (void)drawCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock;
- (void)drawAnimatePathWithCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock;

- (void)clearAll;
- (void)clearArcLine;
- (void)clearAnimateLine;

+ (NSDictionary *)arcLineAlgorithm:(CGPoint)startPoint endPoint:(CGPoint)endPoint;
@end

NS_ASSUME_NONNULL_END
