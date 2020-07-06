//
//  MKMapView+LayerPath.m
//  PZArchLine
//
//  Created by Proz wang on 2020/4/1.
//  Copyright © 2020 Proz wang. All rights reserved.
//

#import "MKMapView+LayerPath.h"
#import <objc/runtime.h>

static char *_startPoint;
static char *_endPoint;
static char *_circlePoint;
static char *_startArc;
static char *_endArc;
static char *_isClock;
static char *_radius;
static char *_isLoopAnimation;
static char *_shapLayer;
static char *_arcLayer;
static char *_methodCache;

NSString * const drawAnimationWithStartPointKey = @"drawAnimationWithStartPointKey";
NSString * const drawCenterPointKey = @"drawCenterPointKey";
NSString * const drawStraightLineWithStartPointKey = @"drawStraightLineWithStartPointKey";
NSString * const drawAnimatePathWithCenterPointKey = @"drawAnimatePathWithCenterPointKey";

#define DURATIONTIME 3
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@implementation MKMapView (LayerPath)

+ (NSDictionary *)arcLineAlgorithm:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    double m = sqrt((startPoint.x - endPoint.x) * (startPoint.x - endPoint.x) + (startPoint.y - endPoint.y) * (startPoint.y - endPoint.y));
    double angleCircle = 60;
    double angleLine = (180 - angleCircle) / 2;
    double r = m / (2 * cos(DEGREES_TO_RADIANS(angleLine)));
    CGPoint centerP = CGPointMake((startPoint.x + endPoint.x)/2, (startPoint.y + endPoint.y)/2);
    
    
    double dx =  (endPoint.x - startPoint.x);
    double dy =  (endPoint.y - startPoint.y);
    double k = dy / dx;
    double l = r * sin(DEGREES_TO_RADIANS(angleLine));
    
    BOOL isLeft = startPoint.x < endPoint.x;
    BOOL isUp = startPoint.y < endPoint.y;
    int directionFactor = 1;
    if ((isLeft && !isUp) || (!isLeft && isUp)) {
        directionFactor = -1;
    }
    
    double circleX = centerP.x - directionFactor * l * fabs(k) / sqrt(1 + k * k);
    double circleY = - circleX / k + (startPoint.x + endPoint.x) / (2 * k) + (startPoint.y + endPoint.y) / 2;
    CGPoint circleCenter = CGPointMake(circleX, circleY);
    double d = fabs(startPoint.x - circleX);
    double j = asin(d/r);
    double angleStartAndCircleCenter = RADIANS_TO_DEGREES(j);
    double angleEndAndCircleCenter = 0;
    double angleStart = angleStartAndCircleCenter;
    double angleEnd = 0;
    BOOL isClockWise = startPoint.x < endPoint.x;
    
    if (circleX > startPoint.x) {
        angleStart = -DEGREES_TO_RADIANS(angleStartAndCircleCenter + 90);
        if (circleX > endPoint.x) {
            if (startPoint.x < endPoint.x) {
                if (startPoint.y > circleY) {
                    angleStart = DEGREES_TO_RADIANS(angleStartAndCircleCenter + 90);
                    angleEndAndCircleCenter = 180 - angleCircle - angleStartAndCircleCenter;
                } else {
                    angleEndAndCircleCenter = angleStartAndCircleCenter - angleCircle;
                }
            } else {
                angleEndAndCircleCenter = angleStartAndCircleCenter + angleCircle;
            }
            angleEnd = -DEGREES_TO_RADIANS(angleEndAndCircleCenter + 90);
        } else {
            angleEndAndCircleCenter = angleCircle - angleStartAndCircleCenter;
            angleEnd = -DEGREES_TO_RADIANS(90 - angleEndAndCircleCenter);
        }
    } else {
        angleStart = -DEGREES_TO_RADIANS(90-angleStartAndCircleCenter);
        if (circleX > endPoint.x) {
            angleEndAndCircleCenter = angleCircle - angleStartAndCircleCenter;
            angleEnd = -DEGREES_TO_RADIANS(angleEndAndCircleCenter + 90);
        } else {
            if (startPoint.x < endPoint.x) {
                angleEndAndCircleCenter = angleStartAndCircleCenter + angleCircle;
            } else {
                if (startPoint.y > circleY) {
                    angleStart = DEGREES_TO_RADIANS(90-angleStartAndCircleCenter);
                    angleEndAndCircleCenter = 180 - angleCircle - angleStartAndCircleCenter;
                } else {
                    angleEndAndCircleCenter = angleStartAndCircleCenter - angleCircle;
                }
            }
            angleEnd = -DEGREES_TO_RADIANS(90 - angleEndAndCircleCenter);
        }
    }
    return @{
        @"centerPoint" : [NSValue valueWithCGPoint:circleCenter],
        @"startArc" : @(angleStart),
        @"endArc" : @(angleEnd),
        @"radius" : @(r),
        @"isClock" : @(isClockWise)
    };
}

- (void)drawRect:(CGRect)rect {
    for (NSString *key in self.dispatchCache) {
        NSDictionary *value = self.dispatchCache[key];
        if ([key isEqualToString:drawAnimationWithStartPointKey]) {
            NSValue *startPoint = value[@"startPoint"];
            NSValue *endPoint = value[@"endPoint"];
            [self animationWithStartPoint:startPoint.CGPointValue endPoint:endPoint.CGPointValue];
        } else if ([key isEqualToString:drawStraightLineWithStartPointKey]) {
            NSValue *startPoint = value[@"startPoint"];
            NSValue *endPoint = value[@"endPoint"];
            [self excuteStraightLineWithStartPoint:startPoint.CGPointValue endPoint:endPoint.CGPointValue];
        } else if ([key isEqualToString:drawCenterPointKey]) {
            NSValue *startPoint = value[@"startPoint"];
            NSValue *centerPoint = value[@"centerPoint"];
            NSNumber *startArc = value[@"startArc"];
            NSNumber *endArc = value[@"endArc"];
            NSNumber *radius = value[@"radius"];
            NSNumber *isClock = value[@"isClock"];
            [self excuteWithCenterPoint:centerPoint.CGPointValue startPoint:startPoint.CGPointValue startArc:startArc.doubleValue endArc:endArc.doubleValue radius:radius.doubleValue isClock:isClock.boolValue];
        } else if ([key isEqualToString:drawAnimatePathWithCenterPointKey]) {
            NSValue *startPoint = value[@"startPoint"];
            NSValue *centerPoint = value[@"centerPoint"];
            NSNumber *startArc = value[@"startArc"];
            NSNumber *endArc = value[@"endArc"];
            NSNumber *radius = value[@"radius"];
            NSNumber *isClock = value[@"isClock"];
            [self animatePathWithCenterPoint:centerPoint.CGPointValue startPoint:startPoint.CGPointValue startArc:startArc.doubleValue endArc:endArc.doubleValue radius:radius.doubleValue isClock:isClock.boolValue];
        }
    }
    [self.dispatchCache removeAllObjects];
}

- (void)drawAnimationWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    [self.dispatchCache setValue:@{
        @"startPoint" : [NSValue valueWithCGPoint:startPoint] ,
        @"endPoint" : [NSValue valueWithCGPoint:endPoint]
    } forKey:drawAnimationWithStartPointKey];
    [self setNeedsDisplay];
}

- (void)drawCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock {
    [self.dispatchCache setValue:@{
        @"centerPoint" : [NSValue valueWithCGPoint:center],
        @"startPoint" : [NSValue valueWithCGPoint:startPoint],
        @"startArc" : @(startArc),
        @"endArc" : @(endArc),
        @"radius" : @(radius),
        @"isClock" : @(isClock)
    } forKey:drawCenterPointKey];
    [self setNeedsDisplay];
}

- (void)drawStraightLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    [self.dispatchCache setValue:@{
        @"startPoint" : [NSValue valueWithCGPoint:startPoint] ,
        @"endPoint" : [NSValue valueWithCGPoint:endPoint]
    }
                          forKey:drawStraightLineWithStartPointKey];
    [self setNeedsDisplay];
}

- (void)drawAnimatePathWithCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock {
    [self.dispatchCache setValue:@{
        @"centerPoint" : [NSValue valueWithCGPoint:center],
        @"startPoint" : [NSValue valueWithCGPoint:startPoint],
        @"startArc" : @(startArc),
        @"endArc" : @(endArc),
        @"radius" : @(radius),
        @"isClock" : @(isClock)
    } forKey:drawAnimatePathWithCenterPointKey];
    [self setNeedsDisplay];
}
#pragma mark - private method
- (void)excuteStraightLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    [self clearArcLine];
    CGPathRef path = [self straightLineWithStartPoint:startPoint endPoint:endPoint];
    self.arcLayer.path = path;
    [self.layer insertSublayer:self.arcLayer atIndex:1];
}

- (void)animationWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    [self clearAnimateLine];
    CGPathRef path = [self straightLineWithStartPoint:startPoint endPoint:endPoint];
    self.shapeLayer.path = path;
    [self.layer insertSublayer:self.shapeLayer above:self.arcLayer];
    self.shapeLayer.anchorPoint = self.layer.anchorPoint;
    CAAnimation *shapeLayerAnimation = [self constructShapeLayerAnimation];
    shapeLayerAnimation.delegate = self;
    [self.shapeLayer addAnimation:shapeLayerAnimation forKey:@"shape"];
}

- (void)excuteWithCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock {
    [self clearArcLine];
    CGPathRef path = [self arcPathWithCenterPoint:center startPoint:startPoint startArc:startArc endArc:endArc radius:radius isClock:isClock];
    self.arcLayer.path = path;
    [self.layer insertSublayer:self.arcLayer atIndex:1];
}

- (void)animatePathWithCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock {
    [self clearAnimateLine];
    CGPathRef path = [self arcPathWithCenterPoint:center startPoint:startPoint startArc:startArc endArc:endArc radius:radius isClock:isClock];
    self.shapeLayer.path = path;
    [self.layer insertSublayer:self.shapeLayer above:self.arcLayer];
    self.shapeLayer.anchorPoint = self.layer.anchorPoint;
    CAAnimation *shapeLayerAnimation = [self constructShapeLayerAnimation];
    shapeLayerAnimation.delegate = self;
    [self.shapeLayer addAnimation:shapeLayerAnimation forKey:@"shape"];
}


- (void)excuteWithStartPoint:(CGPoint)startPoint midPoint:(CGPoint)midPoint endPoint:(CGPoint)endPoint {
    [self clearArcLine];
    CGPathRef path = [self arcPathWithStartPoint:startPoint midPoint:midPoint endPoint:endPoint];
    self.arcLayer.path = path;
    [self.layer insertSublayer:self.arcLayer atIndex:1];
}



- (void)animatePathWithStartPoint:(CGPoint)startPoint midPoint:(CGPoint)midPoint endPoint:(CGPoint)endPoint {
    [self clearAnimateLine];
    CGPathRef path = [self arcPathWithStartPoint:startPoint midPoint:midPoint endPoint:endPoint];
    self.shapeLayer.path = path;
    [self.layer insertSublayer:self.shapeLayer above:self.arcLayer];
    self.shapeLayer.anchorPoint = self.layer.anchorPoint;
    CAAnimation *shapeLayerAnimation = [self constructShapeLayerAnimation];
    shapeLayerAnimation.delegate = self;
    [self.shapeLayer addAnimation:shapeLayerAnimation forKey:@"shape"];
}

- (void)clearArcLine {
    [self.arcLayer removeFromSuperlayer];
    
}
- (void)clearAnimateLine {
    [self.shapeLayer removeFromSuperlayer];
}

- (void)clearAll {
    [self clearArcLine];
    [self clearAnimateLine];
    self.isLoopAnimation = NO;
}

- (CAAnimation *)constructLayerAnimationWithPath:(CGPathRef)path {
    CAKeyframeAnimation *thekeyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    thekeyFrameAnimation.duration        = DURATIONTIME;
    thekeyFrameAnimation.path            = path;
    thekeyFrameAnimation.calculationMode = kCAAnimationPaced;
    return thekeyFrameAnimation;
}

- (CAAnimation *)constructShapeLayerAnimation {
    CABasicAnimation *theStrokeAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    theStrokeAnimation.duration         = DURATIONTIME;
    theStrokeAnimation.fromValue        = @0.f;
    theStrokeAnimation.toValue          = @1.f;
    return theStrokeAnimation;
}

- (CGPathRef)straightLineWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 3;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path moveToPoint:startPoint];
    [path addLineToPoint:endPoint];
    [path stroke];
    return path.CGPath;
}

- (CGPathRef)arcPathWithCenterPoint:(CGPoint)center startPoint:(CGPoint)startPoint startArc:(double)startArc endArc:(double)endArc radius:(double)radius isClock:(BOOL)isClock {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 3;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path moveToPoint:startPoint];
    [path addArcWithCenter:center radius:radius startAngle:startArc endAngle:endArc clockwise:isClock];
    [path stroke];
    return path.CGPath;
}

- (CGPathRef)arcPathWithStartPoint:(CGPoint)startPoint midPoint:(CGPoint)midPoint endPoint:(CGPoint)endPoint {
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 3;
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;
    [path moveToPoint:startPoint];
    [path addQuadCurveToPoint:endPoint controlPoint:midPoint];
    [path stroke];
    return path.CGPath;
}

- (CGPoint)controlPointWithP1:(CGPoint)p1 p2:(CGPoint)p2 {
    CGPoint point = [self centerWithP1:p1 p2:p2];
    CGFloat differY = fabs(p1.y - point.y);
    if (p1.y > p2.y) {
        point.y -= differY;
    } else {
        point.y += differY;
    }
    return point;
}

- (CGPoint)centerWithP1:(CGPoint)p1 p2:(CGPoint)p2 {
    return CGPointMake((p1.x + p2.x) / 2.0f, (p1.y + p2.y) / 2.0f);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if (self.isLoopAnimation) {
        if (self.startPoint.x == self.endPoint.x) {
            [self drawAnimationWithStartPoint:self.startPoint endPoint:self.endPoint];
        } else {
            [self drawAnimatePathWithCenterPoint:self.circlePoint startPoint:self.startPoint startArc:self.startArc endArc:self.endArc radius:self.radius isClock:self.isClock];
        }
    }
}



#pragma mark - setters
- (void)setStartPoint:(CGPoint)startPoint {
    objc_setAssociatedObject(self, &_startPoint, [NSValue valueWithCGPoint:startPoint], OBJC_ASSOCIATION_COPY);
}

- (void)setEndPoint:(CGPoint)endPoint {
    objc_setAssociatedObject(self, &_endPoint, [NSValue valueWithCGPoint:endPoint], OBJC_ASSOCIATION_COPY);
}

- (void)setCirclePoint:(CGPoint)circlePoint {
    objc_setAssociatedObject(self, &_circlePoint, [NSValue valueWithCGPoint:circlePoint], OBJC_ASSOCIATION_COPY);
}

- (void)setStartArc:(double)startArc {
    objc_setAssociatedObject(self, &_startArc, @(startArc), OBJC_ASSOCIATION_COPY);
}

- (void)setEndArc:(double)endArc {
    objc_setAssociatedObject(self, &_endArc, @(endArc), OBJC_ASSOCIATION_COPY);
}

- (void)setIsClock:(BOOL)isClock {
    objc_setAssociatedObject(self, &_isClock, @(isClock), OBJC_ASSOCIATION_COPY);
}

- (void)setRadius:(double)radius {
    objc_setAssociatedObject(self, &_radius, @(radius), OBJC_ASSOCIATION_COPY);
}

- (void)setIsLoopAnimation:(BOOL)isLoopAnimation {
    objc_setAssociatedObject(self, &_isLoopAnimation, @(isLoopAnimation), OBJC_ASSOCIATION_RETAIN);
}

- (void)setArcLayer:(CAShapeLayer *)arcLayer {
    objc_setAssociatedObject(self, &_arcLayer, arcLayer, OBJC_ASSOCIATION_RETAIN);
}

- (void)setShapeLayer:(CAShapeLayer *)shapeLayer {
    objc_setAssociatedObject(self, &_shapLayer, shapeLayer, OBJC_ASSOCIATION_RETAIN);
}

- (void)setDispatchCache:(NSMutableDictionary *)dispatchCache {
    objc_setAssociatedObject(self, &_methodCache, dispatchCache, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - getters
- (CGPoint)startPoint {
    NSValue *value = objc_getAssociatedObject(self, &_startPoint);
    return  value.CGPointValue;
}

- (CGPoint)endPoint {
    NSValue *value = objc_getAssociatedObject(self, &_endPoint);
    return  value.CGPointValue;
}

- (CGPoint)circlePoint {
    NSValue *value = objc_getAssociatedObject(self, &_circlePoint);
    return  value.CGPointValue;
}

- (double)startArc {
    NSNumber *value = objc_getAssociatedObject(self, &_startArc);
    return  value.doubleValue;
}

- (double)endArc {
    NSNumber *value = objc_getAssociatedObject(self, &_endArc);
    return  value.doubleValue;
}

- (BOOL)isClock {
    NSNumber *value = objc_getAssociatedObject(self, &_isClock);
    return  value.boolValue;
}

- (double)radius {
    NSNumber *value = objc_getAssociatedObject(self, &_radius);
    return  value.doubleValue;
}

- (BOOL)isLoopAnimation {
    NSNumber *value = objc_getAssociatedObject(self, &_isLoopAnimation);
    return  value.boolValue;
}

- (CAShapeLayer *)shapeLayer {
    CAShapeLayer * value = objc_getAssociatedObject(self, &_shapLayer);
    if (!value) {
        value = [[CAShapeLayer alloc] init];
        value.lineWidth = 3;
        value.strokeColor = [UIColor blackColor].CGColor;
        value.fillColor = [UIColor clearColor].CGColor;
        value.lineJoin = kCALineCapRound;
        objc_setAssociatedObject(self, &_shapLayer, value, OBJC_ASSOCIATION_RETAIN);
    }
    return value;
}

- (CAShapeLayer *)arcLayer {
    CAShapeLayer * value = objc_getAssociatedObject(self, &_arcLayer);
    if (!value) {
        value = [[CAShapeLayer alloc] init];
        value.lineWidth = 3;
        value.strokeColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
        value.fillColor = [UIColor clearColor].CGColor;
        value.lineJoin = kCALineCapRound;
        objc_setAssociatedObject(self, &_arcLayer, value, OBJC_ASSOCIATION_RETAIN);
    }
    return value;
}

- (NSMutableDictionary *)dispatchCache {
    NSMutableDictionary *value = objc_getAssociatedObject(self, &_methodCache);
    if (!value) {
        value = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &_methodCache, value, OBJC_ASSOCIATION_RETAIN);
    }
    return  value;
}
@end
