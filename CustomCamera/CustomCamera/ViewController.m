//
//  ViewController.m
//  CustomCamera
//
//  Created by wyy on 16/8/3.
//  Copyright © 2016年 yyx. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
typedef  void(^LockStateBlock)(AVCaptureDevice *captureDevice);
#define ScreenWidth  [[UIScreen mainScreen] bounds].size.width
#define ScreenHeight [[UIScreen mainScreen] bounds].size.height
#define bottomHeigth 80
#define toolHeight   50
#define toolIconHeigth 30
@interface ViewController ()

//UI
@property (nonatomic, strong) UIView *toolView;
@property (nonatomic, strong) UIView *previewContainer;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *cameraButton;
@property (nonatomic, strong) UIImageView *dispalayPreviousImage;
@property (nonatomic, strong) UIButton *flashlightButton; //闪光
@property (nonatomic, strong) UIImageView *spotlightImageVIew;//聚光
//AVfoundation
@property (nonatomic, strong) AVCaptureSession *captureSesstion;//AVFoundation 核心类
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;//display video as it is being captured by an input device
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;//capture data from an AVCaptureDevice object.
@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput; //capture a high-quality still image with accompanying metadata.


//mark
@property (nonatomic, assign) FlashlightStatue ligthStatue;
@property (nonatomic, assign) CameraType cameraType;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
//    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
//    NSLog(@"%ld",authStatus);
    self.ligthStatue = FlashlightKeepingOff;
    
    
    //capture Device 系统通过AVCaptureDevice来得到和管理设备的输入捕获设备
    AVCaptureDevice *device = [self _getCameraTypeOfDevice:AVCaptureDevicePositionBack];
    if (device) {
        self.cameraType = CameraTypeBackFacing;
    }
    
    
    //set input flow
    NSError *error = nil;
    _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"取得设备输入对象时出错，错误原因：%@",error.localizedDescription);
        return;
    }
    //set output image
    _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    [_imageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
    
    //init Session
    _captureSesstion = [[AVCaptureSession alloc] init];
    if ([_captureSesstion canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {//分辨率太高会导致前置摄像头切换失败。毕竟渣嘛
        _captureSesstion.sessionPreset=AVCaptureSessionPreset1920x1080;
    }
    
    if ([_captureSesstion canAddInput:_deviceInput]) {
        [_captureSesstion addInput:_deviceInput];
    }else{
        NSLog(@"添加输入失败");
    }
    
    if ([_captureSesstion canAddOutput:_imageOutput]) {
        [_captureSesstion addOutput:_imageOutput];
    }else{
        NSLog(@"添加输出失败");
    }
    
    

    [self.view addSubview:self.toolView];
    [self.view addSubview:self.previewContainer];
    [self.view addSubview:self.bottomView];
    [self addNotificationForDevice:device];
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_captureSesstion startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_captureSesstion stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - private method
//拿到摄像头的类型
- (AVCaptureDevice *)_getCameraTypeOfDevice : (AVCaptureDevicePosition)Position{
    NSArray *parts = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *part in parts) {
        if ([part position] == Position) {
             NSLog(@"%@ == %ld",part,part.position);
            return part;
        }
      
    }
    return  nil;
}

/**
 *  设置点击后的焦距坐标
 *
 *  @param point <#point description#>
 */
- (void)_setSpotlightPosition : (CGPoint)point{
    _spotlightImageVIew.center = point;
    _spotlightImageVIew.transform=CGAffineTransformMakeScale(1.8, 1.8);
    [UIView animateWithDuration:.6 animations:^{
        _spotlightImageVIew.alpha = 1;
        _spotlightImageVIew.transform=CGAffineTransformIdentity;

    } completion:^(BOOL finished) {

        _spotlightImageVIew.alpha = 0;
    }];
}

- (void)_updateLockForConfigturation : (LockStateBlock)lockblock{
    AVCaptureDevice *device = [_deviceInput device];
    //在session中相机设备中完成的所有操作和配置都是利用block调用的。相机设备在改变某些参数前必须先锁定，直到改变结束才能解锁
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        lockblock(device);
        [device unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误：%@",error.localizedDescription);
    }
}

/**
 *  设置聚焦点和曝光模式
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
  
    [self _updateLockForConfigturation:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeLocked];//焦距调整
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];//左上角为{0，0} 右下角为{1，1}
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeLocked];//曝光
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];//左上角为{0，0} 右下角为{1，1}
        }
    }];
}

/**
 *  设置闪光灯模式
 *
 *  @param flashMode 闪光灯模式
 */
-(void)_setFlashMode:(AVCaptureFlashMode )flashMode{
    [self _updateLockForConfigturation:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFlashModeSupported:flashMode]) {
            [captureDevice setFlashMode:flashMode];
        }
    }];
}

#pragma mark -- nitofication
- (void)addNotificationForDevice : (AVCaptureDevice *)device{
    [self _updateLockForConfigturation:^(AVCaptureDevice *captureDevice) {
        //If subject area change monitoring is enabled, the capture device object sends an AVCaptureDeviceSubjectAreaDidChangeNotification whenever it detects a change to the subject area
        device.subjectAreaChangeMonitoringEnabled = YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(subjectAreaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:device];
}

- (void)subjectAreaChange:(NSNotification *)notification{
    NSLog(@"区域变化");
}
#pragma mark - action
- (void)takePicturesOrVedios{
    AVCaptureConnection *connection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    [_imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            _dispalayPreviousImage.image = image;
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
       
    }];
}

- (void)amplifierTheCamera{
    NSLog(@"放大");
}


- (void)cancelAmplifierTheCamera{
    NSLog(@"取消放大");
}

- (void)updateTheFlashlightStatue{//只做了开启和关闭 没有做自动
    if (self.ligthStatue == FlashlightKeepingOff) {
        self.ligthStatue = FlashlightKeepingOn;
        [self _setFlashMode:AVCaptureFlashModeOn];
         [_flashlightButton setImage:[UIImage imageNamed:@"开启闪光灯"] forState:0];
        
    }else if(self.ligthStatue == FlashlightKeepingOn){
        self.ligthStatue = FlashlightKeepingOff;
         [_flashlightButton setImage:[UIImage imageNamed:@"关闭闪光灯"] forState:0];
        [self _setFlashMode:AVCaptureFlashModeOff];
    }

}

- (void)switchTheTypeOfCamera{
     NSLog(@"切换摄像头的前后置");
//    AVCaptureDevicePosition position;
//    if (self.cameraType == CameraTypeBackFacing) {
//        self.cameraType = CameraTypeFrontFacing;
//        position = AVCaptureDevicePositionFront;
//    }else if (self.cameraType == CameraTypeFrontFacing){
//        self.cameraType = CameraTypeBackFacing;
//         position = AVCaptureDevicePositionBack;
//    }
    
    AVCaptureDevice *currentDevice=[_deviceInput device];
    AVCaptureDevicePosition currentPosition=[currentDevice position];
    //    [self removeNotificationFromCaptureDevice:currentDevice];
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition=AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition=AVCaptureDevicePositionBack;
    }
    toChangeDevice=[self _getCameraTypeOfDevice:toChangePosition];
    //    [self addNotificationToCaptureDevice:toChangeDevice];
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput=[[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [_captureSesstion beginConfiguration];
    //移除原有输入对象
    [_captureSesstion removeInput:_deviceInput];
    //添加新的输入对象
    if ([_captureSesstion canAddInput:toChangeDeviceInput]) {
        [_captureSesstion addInput:toChangeDeviceInput];
        _deviceInput=toChangeDeviceInput;
    }
    //提交会话配置
    [_captureSesstion commitConfiguration];
}

- (void)handleTapGestureOnViewContainer : (UITapGestureRecognizer *)tapGesture{
    NSLog(@"光标");
    CGPoint point= [tapGesture locationInView:_previewContainer];
    CGPoint cameraPoint= [_previewLayer captureDevicePointOfInterestForPoint:point];
   
//    NSLog(@"%@==%@",NSStringFromCGPoint(point), NSStringFromCGPoint(cameraPoint));
    [self _setSpotlightPosition:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:cameraPoint];
}
#pragma mark - get UI
- (UIView *)toolView{
    if (!_toolView) {
        _toolView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, ScreenWidth, toolHeight)];
        _toolView.backgroundColor = [UIColor blackColor];
        
        _flashlightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashlightButton.frame = CGRectMake(50, (toolHeight -toolIconHeigth)/2, toolIconHeigth, toolIconHeigth);
        if (self.ligthStatue == FlashlightKeepingOff) {
              [_flashlightButton setImage:[UIImage imageNamed:@"关闭闪光灯"] forState:0];
        }else if (self.ligthStatue == FlashlightKeepingOn){
              [_flashlightButton setImage:[UIImage imageNamed:@"开启闪光灯"] forState:0];
        }
      
        [_flashlightButton addTarget:self action:@selector(updateTheFlashlightStatue) forControlEvents:UIControlEventTouchUpInside];
        [_toolView addSubview:_flashlightButton];
        
        UIButton *switchCameraTypeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        switchCameraTypeButton.frame = CGRectMake(ScreenWidth -50, (toolHeight -toolIconHeigth)/2, toolIconHeigth, toolIconHeigth);
        [switchCameraTypeButton setImage:[UIImage imageNamed:@"前后摄像头转换"] forState:0];
        [switchCameraTypeButton addTarget:self action:@selector(switchTheTypeOfCamera) forControlEvents:UIControlEventTouchUpInside];
        [_toolView addSubview:switchCameraTypeButton];
        
    }
    return _toolView;
}

- (UIView *)previewContainer{
    if (!_previewContainer) {
        _previewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, toolHeight +20, ScreenWidth, ScreenHeight - 64 -bottomHeigth)];
        _previewContainer.backgroundColor = [UIColor clearColor];
        
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSesstion];
        CALayer *layer = _previewContainer.layer;
        layer.masksToBounds = YES;
        _previewLayer.frame = layer.bounds;
        _previewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//填充模式
        [layer addSublayer:_previewLayer];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureOnViewContainer:)];
        [_previewContainer addGestureRecognizer:tapGesture];
        
        
        _spotlightImageVIew = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _spotlightImageVIew.image = [UIImage imageNamed:@"焦距"];
        _spotlightImageVIew.alpha = 0;
        [_previewContainer addSubview:_spotlightImageVIew];
    }
    return _previewContainer;
}

- (UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight -bottomHeigth, ScreenWidth, bottomHeigth)];
        _bottomView.backgroundColor = [UIColor blackColor];
         _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.frame = CGRectMake((ScreenWidth - 60)/2, 10, 60, 60);
        [_cameraButton setImage:[UIImage imageNamed:@"摄像头1"] forState:0];
        [_cameraButton addTarget:self action:@selector(takePicturesOrVedios) forControlEvents:UIControlEventTouchUpInside];
        [_cameraButton addTarget:self action:@selector(amplifierTheCamera) forControlEvents:UIControlEventTouchDown];
        [_cameraButton addTarget:self action:@selector(cancelAmplifierTheCamera) forControlEvents:UIControlEventTouchUpOutside];

        [_bottomView addSubview:_cameraButton];
        
        _dispalayPreviousImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, (bottomHeigth - 40)/2, 40, 40)];
        _dispalayPreviousImage.backgroundColor = [UIColor whiteColor];
        _dispalayPreviousImage.contentMode = 1;
        [_bottomView addSubview:_dispalayPreviousImage];
        
    }
    return _bottomView;
}

@end
