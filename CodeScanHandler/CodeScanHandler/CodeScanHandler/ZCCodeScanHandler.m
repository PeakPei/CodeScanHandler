//
//  ZCCodeScanHandler.m
//  CodeScanHandler
//
//  Created by CeceZhao on 2018/6/22.
//  Copyright © 2018年 CeceZhao. All rights reserved.
//

#import "ZCCodeScanHandler.h"
@import AVFoundation;

static ZCCodeScanHandler * codeScanHandler;

@interface ZCCodeScanHandler()<AVCaptureMetadataOutputObjectsDelegate> {
    AVCaptureDevice * c_device;
    AVCaptureInput * c_input;
    AVCaptureMetadataOutput * c_output;
    AVCaptureSession * c_session;
    AVCaptureVideoPreviewLayer * c_layer;
    void(^c_scanqrBlock)(NSString *);
}
@end

@implementation ZCCodeScanHandler
+ (UIImage *)qrCodeWithString:(NSString *)string {
    return [self qrCodeWithString:string logo:nil];
}
+ (UIImage *)qrCodeWithString:(NSString *)string logo:(UIImage *)logo {
    // 1.实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复滤镜的默认属性 (因为滤镜有可能保存上一次的属性)
    [filter setDefaults];
    // 3.将字符串转换成NSdata
    NSData *data  = [string dataUsingEncoding:NSUTF8StringEncoding];
    // 4.通过KVO设置滤镜, 传入data, 将来滤镜就知道要通过传入的数据生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    CIImage * outCIImage = [filter outputImage];
    //    UIImage * outImage = [UIImage imageWithCIImage:outCIImage];
    UIImage * outImage = [self _createUIImageFormCIImage:outCIImage withSize:300];
    
    if (logo) {
        //添加logo
        outImage = [self remixImage:logo
                        toBackImage:outImage
                       frameOfImage:^CGRect(CGSize imageSize) {
                           CGFloat imgwd = imageSize.width/6;
                           CGRect frame = CGRectMake(imageSize.width/2-imgwd/2, imageSize.height/2-imgwd/2, imgwd, imgwd);
                           return frame;
                       }];
    }
    
    return outImage;
}

//根据空白合成图
+ (UIImage *)makeQrCode:(UIImage *)qrCode
                toImage:(UIImage *)image {
    return nil;
}

//根据位置合成图
+ (UIImage *)remixImage:(UIImage *)image
            toBackImage:(UIImage *)backImage
           frameOfImage:(CGRect(^)(CGSize))frameBlock {
    CGSize backSize = CGSizeMake(backImage.size.width, backImage.size.height);
    //    if (backSize.width > 500) {
    backSize.height = 500/backSize.width*backSize.height;
    backSize.width = 500;
    //    }
    //背景
    UIView * backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, backSize.width, backSize.height)];
    
    //底图
    UIImageView * imageV = [[UIImageView alloc] initWithFrame:backView.bounds];
    [backView addSubview:imageV];
    [imageV setImage:backImage];
    
    //二维码
    if (frameBlock) {
        CGRect frame = frameBlock(backView.bounds.size);
        UIImageView * qrV = [[UIImageView alloc] initWithFrame:frame];
        [backView addSubview:qrV];
        [qrV setImage:image];
    }
    
    UIImage * outImage = [self _remixImageWithImageView:backView];
    return outImage;
}

+ (NSString *)scanQrCodeWithImage:(UIImage *)qrCode {
    NSData *data = UIImagePNGRepresentation(qrCode);
    CIImage *ciimage = [CIImage imageWithData:data];
    if (ciimage) {
        CIDetector *qrDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:[CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@(YES)}] options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        NSArray *resultArr = [qrDetector featuresInImage:ciimage];
        if (resultArr.count >0) {
            CIFeature *feature = resultArr[0];
            CIQRCodeFeature *qrFeature = (CIQRCodeFeature *)feature;
            NSString *result = qrFeature.messageString;
            
            return result;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

+ (UIView *)scanQrCodeWithFrame:(CGRect)frame successBlock:(void (^)(NSString *))codeBlock {
    codeScanHandler = [[ZCCodeScanHandler alloc] init];
    // Device
    codeScanHandler->c_device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // Input
    codeScanHandler->c_input = [AVCaptureDeviceInput deviceInputWithDevice:codeScanHandler->c_device error:nil];
    // Output
    codeScanHandler->c_output = [[AVCaptureMetadataOutput alloc]init];
    
    [codeScanHandler->c_output setMetadataObjectsDelegate:codeScanHandler queue:dispatch_get_main_queue()];
    // Session
    codeScanHandler->c_session = [[AVCaptureSession alloc]init];
    [codeScanHandler->c_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    //链接输入输出
    if ([codeScanHandler->c_session canAddInput:codeScanHandler->c_input])
    {
        [codeScanHandler->c_session addInput:codeScanHandler->c_input];
    }
    if ([codeScanHandler->c_session canAddOutput:codeScanHandler->c_output])
    {
        [codeScanHandler->c_session addOutput:codeScanHandler->c_output];
    }
    
    //设置条码类型
    codeScanHandler->c_output.metadataObjectTypes =@[AVMetadataObjectTypeQRCode];
    
    //添加layer
    UIView * outView = [[UIView alloc] initWithFrame:frame];
    codeScanHandler->c_layer = [AVCaptureVideoPreviewLayer layerWithSession:codeScanHandler->c_session];
    codeScanHandler->c_layer.videoGravity =AVLayerVideoGravityResizeAspectFill;
    codeScanHandler->c_layer.frame = outView.layer.bounds;
    [outView.layer insertSublayer:codeScanHandler->c_layer atIndex:0];
    [codeScanHandler->c_session startRunning];
    
    codeScanHandler->c_scanqrBlock = codeBlock;
    return outView;
}

//停止扫描
+ (void)stopScanQrCode {
    if (codeScanHandler) {
        [codeScanHandler->c_session stopRunning];
        codeScanHandler->c_scanqrBlock = nil;
        codeScanHandler->c_layer = nil;
        codeScanHandler->c_output = nil;
        codeScanHandler->c_input = nil;
        codeScanHandler->c_device = nil;
        codeScanHandler->c_session = nil;
        codeScanHandler = nil;
    }
}

//二维码扫描回调
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if ([metadataObjects count] >0){
        //停止扫描
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects[0];
        NSString * stringValue = metadataObject.stringValue;
        if (c_scanqrBlock) {
            c_scanqrBlock(stringValue);
        }
        [ZCCodeScanHandler stopScanQrCode];
    }
}

#pragma mark - 辅助方法
//CIImage转UIImage
+ (UIImage *)_createUIImageFormCIImage:(CIImage *)image
                              withSize:(CGFloat)size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

/**
 将不同层压成一张
 */
+ (UIImage *)_remixImageWithImageView:(UIView *)remixImageView {
    //截取图片
    UIGraphicsBeginImageContextWithOptions(remixImageView.frame.size, NO, 10.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [remixImageView.layer renderInContext:ctx];
    UIImage *imgDraw = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imgDraw;
}

@end
