//
//  ViewController.h
//  CustomCamera
//
//  Created by wyy on 16/8/3.
//  Copyright © 2016年 yyx. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, FlashlightStatue){//闪关灯类型
    FlashlightKeepingOn,
    FlashlightKeepingOff //default
};

typedef NS_ENUM(NSInteger, CameraType){//摄像头类型
    CameraTypeBackFacing,//default
    CameraTypeFrontFacing
    
};
@interface ViewController : UIViewController


@end

