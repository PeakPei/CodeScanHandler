//
//  ViewController.m
//  CodeScanHandler
//
//  Created by CeceZhao on 2018/6/22.
//  Copyright © 2018年 CeceZhao. All rights reserved.
//

#import "ViewController.h"
#import "ZCCodeScanHandler.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    NSString * shareUrl=@"http://www.baidu.com";//二维码分享链接
    UIImage * baseImage=[UIImage imageNamed:@""];//底部的分享图
    //使用
    
    //创建 中间带logo的二维码图片
    UIImage * codeImage=[ZCCodeScanHandler qrCodeWithString:shareUrl logo:[UIImage imageNamed:@"app_logo"]];
    //根据UI设计的底图 和创建的二维码图片 生成一张最终的推广分享图
    UIImage * shareImage=[ZCCodeScanHandler remixImage:codeImage toBackImage:baseImage frameOfImage:^CGRect(CGSize upImageSize) {
        CGFloat width=upImageSize.width*0.25;
        return CGRectMake(upImageSize.width*0.5-width*0.5, upImageSize.height*0.76, width, width);
    }];
    //shareImage 就是最终的分享图
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
