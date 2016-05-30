//
//  ViewController.m
//  SavePhotoToAppAlbum
//
//  Created by  江苏 on 16/5/30.
//  Copyright © 2016年 jiangsu. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *imageV;

@end

@implementation ViewController


static NSString* JSAssetCollectionTitle=@"JS-TestMyApp";

- (void)viewDidLoad {
    [super viewDidLoad];
 
}

- (IBAction)saveAction {
    
    //如果图片还未下载完成，直接返回
    if ( self.imageV.image==nil) {
        NSLog(@"图片没有下载完哦");
        return;
    }else{
        //1.判断授权状态
        PHAuthorizationStatus status=[PHPhotoLibrary authorizationStatus];
        
        if (status==PHAuthorizationStatusRestricted) {//家长控制的无法访问相册
            
            NSLog(@"因为系统原因，无法访问相册！");
        }else if (status==PHAuthorizationStatusDenied){//用户自己选择拒绝
            NSLog(@"请打开允许访问相册开关！");
        }else if (status==PHAuthorizationStatusAuthorized){//用户允许访问
            [self saveImage];
        }else if (status==PHAuthorizationStatusNotDetermined){//用户没有选择相册访问权限
            //弹窗请求授权,如果授权成功，执行保存，否则什么都不处理
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status==PHAuthorizationStatusAuthorized){//用户允许访问
                    [self saveImage];
                }
            }];
        }
    }
    
    
}

-(void)saveImage{
    // PHAsset的标识, 利用这个标识可以找到对应的PHAsset对象(图片对象)
    __block NSString *assetLocalIdentifier = nil;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //1.保存图片到相机胶卷中
        //创建图片的请求
        assetLocalIdentifier=[PHAssetCreationRequest creationRequestForAssetFromImage:self.imageV.image].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success==NO) {
            [self showError:@"保存图片失败"];
            return ;
        }
        
        //2.获得相薄
        PHAssetCollection* createdAssetCollection=[self createdAssetCollection];
        if (createdAssetCollection==nil) {
            [self showError:@"创建相薄失败！"];
            return;
        }
        
        //3.添加相机交卷中的图片到本app对应的相薄中
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            //获得图片
            PHAsset* asset=[PHAsset fetchAssetsWithLocalIdentifiers:@[assetLocalIdentifier] options:nil].lastObject;
            
            //创建添加图片到相薄中的请求
            PHAssetCollectionChangeRequest *request=[PHAssetCollectionChangeRequest changeRequestForAssetCollection:createdAssetCollection];
            
            //添加图片到相薄中
            [request addAssets:@[asset]];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            
            if (success==YES) {
                [self showSuccess:@"图片保存成功！"];
            }else{
                [self showError:@"图片保存失败"];
            }
        }];
    }];
    
}

/**
 *获取相薄
 */
-(PHAssetCollection* )createdAssetCollection{
    //从已经存在的相薄中查找这个应用对应的相薄
    PHFetchResult* assetCollections=[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    for (PHAssetCollection* assetCollection in assetCollections) {
        if ([assetCollection.localizedTitle isEqualToString:JSAssetCollectionTitle]) {
            return assetCollection;
        }
    }
    
    //没有找到对应的相薄，创建新的相薄
    NSError* error=nil;
    
    __block NSString* assetCollectionLocalIndentifier=nil;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        //创建相薄的请求
        assetCollectionLocalIndentifier=[PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:JSAssetCollectionTitle].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    //如果有错误信息，直接返回
    if (error) return nil;
    
    //没有错误，获得刚才创建的相薄，并返回
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[assetCollectionLocalIndentifier] options:nil].lastObject;
}

-(void)showSuccess:(NSString*)text{
    NSLog(@"%@",text);
}

-(void)showError:(NSString*)text{
    NSLog(@"%@",text);
}
@end
