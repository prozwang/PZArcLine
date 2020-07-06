//
//  ArcViewController.m
//  PZArchLine
//
//  Created by Proz wang on 2019/7/4.
//  Copyright © 2019 Proz wang. All rights reserved.
//

#import "ArcViewController.h"
#import "MKMapView+LayerPath.h"


@interface ArcViewController ()<MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, assign) CLLocationCoordinate2D startLocation;
@property (nonatomic, assign) CLLocationCoordinate2D endLocation;
@property (nonatomic, strong) MKAnnotationView *startAnnotationView;
@property (nonatomic, strong) MKAnnotationView *endAnnotationView;
@property (nonatomic, strong) MKPointAnnotation *startPointAnnotation;
@property (nonatomic, strong) MKPointAnnotation *endPointAnnotation;
@property (nonatomic, assign) BOOL showPath;
@property (nonatomic, assign) BOOL isSelectTouch;
@property (nonatomic, assign) BOOL isSelectDestinationTouch;

@property (nonatomic, strong) UIView *bgContentView;
@property (nonatomic, strong) UIButton *locationButton;


@end

@implementation ArcViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    self.startLocation = CLLocationCoordinate2DMake(22.33333333, 114.222222);
    self.endLocation = CLLocationCoordinate2DMake(23.3333333, 112.33333333);
    [self addAnnotation];
    self.showPath = YES;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setShowPath:(BOOL)showPath {
    _showPath = showPath;
    if (showPath) {
        [self drawArcLine];
        [self startPathAnimation];
    } else {
        [self stopPathAnimation];
        [self.mapView clearArcLine];
    }
}

#pragma mark - privateMethod
- (void)setupUI {
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.bgContentView];
    [self.bgContentView addSubview:self.locationButton];
    self.locationButton.frame = CGRectMake(10, 100, 200, 50);
}

- (void)addAnnotation {
    [self.mapView addAnnotations:@[self.startPointAnnotation,self.endPointAnnotation]];
}

- (void)didClickButton:(UIButton *)sender {
    [self.mapView clearAll];
    [self.mapView clearAnimateLine];
}

#pragma mark - ArcLineMethods



- (void)drawArcLine {
    if (self.startPointAnnotation.coordinate.latitude == 0) {
        return;
    }
    [self.mapView clearArcLine];
    
    CGPoint startPoint = [self.mapView convertCoordinate:self.startPointAnnotation.coordinate toPointToView:self.mapView];
    CGPoint endPoint = [self.mapView convertCoordinate:self.endPointAnnotation.coordinate toPointToView:self.mapView];
    
    NSDictionary *dict = [MKMapView arcLineAlgorithm:startPoint endPoint:endPoint];
    NSValue *centerPoint = dict[@"centerPoint"];
    NSNumber *startArc = dict[@"startArc"];
    NSNumber *endArc = dict[@"endArc"];
    NSNumber *radius = dict[@"radius"];
    NSNumber *isClock = dict[@"isClock"];
    
    if (startPoint.x == endPoint.x) {
        [self.mapView drawStraightLineWithStartPoint:startPoint endPoint:endPoint];
    } else {
        [self.mapView drawCenterPoint:centerPoint.CGPointValue startPoint:startPoint startArc:startArc.doubleValue endArc:endArc.doubleValue radius:radius.doubleValue isClock:isClock.boolValue];
    }
}

- (void)stopPathAnimation {
    self.mapView.isLoopAnimation = NO;
    [self.mapView clearAnimateLine];
}

- (void)startPathAnimation {
    if (self.startPointAnnotation.coordinate.latitude == 0) {
        return;
    }
    CGPoint startPoint = [self.mapView convertCoordinate:self.startPointAnnotation.coordinate toPointToView:self.view];
    CGPoint endPoint = [self.mapView convertCoordinate:self.endPointAnnotation.coordinate toPointToView:self.view];

    NSDictionary *dict = [MKMapView arcLineAlgorithm:startPoint endPoint:endPoint];
    NSValue *centerPoint = dict[@"centerPoint"];
    NSNumber *startArc = dict[@"startArc"];
    NSNumber *endArc = dict[@"endArc"];
    NSNumber *radius = dict[@"radius"];
    NSNumber *isClock = dict[@"isClock"];
    
    self.mapView.startPoint = startPoint;
    self.mapView.endPoint = endPoint;
    self.mapView.circlePoint = centerPoint.CGPointValue;
    self.mapView.startArc = startArc.doubleValue;
    self.mapView.endArc = endArc.doubleValue;
    self.mapView.radius = radius.doubleValue;
    self.mapView.isClock = isClock.boolValue;
    self.mapView.isLoopAnimation = YES;
    if (startPoint.x == endPoint.x) {
        [self.mapView drawAnimationWithStartPoint:startPoint endPoint:endPoint ];
    } else {
        [self.mapView drawAnimatePathWithCenterPoint:centerPoint.CGPointValue startPoint:startPoint startArc:startArc.doubleValue endArc:endArc.doubleValue radius:radius.doubleValue isClock:isClock.boolValue];
    }
    
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (annotation == self.startPointAnnotation) {
        return self.startAnnotationView;
    } else if (annotation == self.endPointAnnotation) {
        return self.endAnnotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateEnding) {
        [view setDragState:MKAnnotationViewDragStateNone animated:YES];
    } else if (newState == MKAnnotationViewDragStateCanceling) {
        [view setDragState:MKAnnotationViewDragStateNone animated:YES];
    }
    if (self.showPath) {
        [self drawArcLine];
        [self startPathAnimation];
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (self.showPath) {
        [mapView clearAll];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if (self.showPath) {
        [self drawArcLine];
        [self startPathAnimation];
    }
}


#pragma mark - lazyloads

- (MKPointAnnotation *)startPointAnnotation {
    if (!_startPointAnnotation) {
        _startPointAnnotation = [[MKPointAnnotation alloc] init];
        _startPointAnnotation.coordinate = self.startLocation;
    }
    return _startPointAnnotation;
}

- (MKPointAnnotation *)endPointAnnotation {
    if (!_endPointAnnotation) {
        _endPointAnnotation = [[MKPointAnnotation alloc] init];
        _endPointAnnotation.coordinate = self.endLocation;
    }
    return _endPointAnnotation;
}

- (MKAnnotationView *)startAnnotationView {
    if (!_startAnnotationView) {
        _startAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:self.startPointAnnotation reuseIdentifier:@"origin"];
        _startAnnotationView.image = [UIImage imageNamed:@"map_start"];
        _startAnnotationView.centerOffset = CGPointMake(0, -20);
        [_startAnnotationView setDraggable:YES];
    }
    return _startAnnotationView;
}

- (MKAnnotationView *)endAnnotationView {
    if (!_endAnnotationView) {
        _endAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:self.endPointAnnotation reuseIdentifier:@"destination"];
        _endAnnotationView.image = [UIImage imageNamed:@"map_end"];
        _endAnnotationView.centerOffset = CGPointMake(0, -20);
        [_endAnnotationView setDraggable:YES];
    }
    return _endAnnotationView;
}

- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _mapView.delegate = self;
        _mapView.zoomEnabled = YES;
        _mapView.showsUserLocation = YES;
        _mapView.rotateEnabled = NO;
        _mapView.centerCoordinate = CLLocationCoordinate2DMake(22.526444, 113.947649);
    }
    return _mapView;
}


- (UIView *)bgContentView {
    if (!_bgContentView) {
        _bgContentView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 200, [UIScreen mainScreen].bounds.size.width, 200)];
        _bgContentView.backgroundColor = [UIColor whiteColor];
    }
    return _bgContentView;
}



- (UIButton *)locationButton {
    if (!_locationButton) {
        _locationButton = [[UIButton alloc] init];
        [_locationButton addTarget:self action:@selector(didClickButton:) forControlEvents:UIControlEventTouchUpInside];
        [_locationButton setBackgroundColor:[UIColor redColor]];
        [_locationButton setTitle:@"清除" forState:UIControlStateNormal];
    }
    return _locationButton;
}

//- (LayerPath *)layerPath {
//    if (!_layerPath) {
//        _layerPath = [[LayerPath alloc] init];
//    }
//    return _layerPath;
//}


@end


