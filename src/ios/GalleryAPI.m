    #import <Cordova/CDV.h>

    #import "GalleryAPI.h"

    #define kDirectoryName @"mendr"

    @interface GalleryAPI ()

    @end

    @implementation GalleryAPI

    - (void) checkPermission:(CDVInvokedUrlCommand*)command {
        [self.commandDelegate runInBackground:^{
            __block NSDictionary *result;
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];

            if (status == PHAuthorizationStatusAuthorized) {
                // Access has been granted.
                result = @{@"success":@(true), @"message":@"Authorized"};
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                            callbackId:command.callbackId];
            }

            else if (status == PHAuthorizationStatusDenied) {
                // Access has been denied.
                result = @{@"success":@(false), @"message":@"Denied"};
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                            callbackId:command.callbackId];
            }

            else if (status == PHAuthorizationStatusNotDetermined) {

                // Access has not been determined.
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {

                    if (status == PHAuthorizationStatusAuthorized) {
                        // Access has been granted.
                        result = @{@"success":@(true), @"message":@"Authorized"};
                        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                                    callbackId:command.callbackId];
                    }

                    else {
                        // Access has been denied.
                        result = @{@"success":@(false), @"message":@"Denied"};
                        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                                    callbackId:command.callbackId];
                    }
                }];
            }

            else if (status == PHAuthorizationStatusRestricted) {
                // Restricted access - normally won't happen.
                result = @{@"success":@(false), @"message":@"Restricted"};
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                            callbackId:command.callbackId];
            }
        }];
    }

    - (void)getAlbums:(CDVInvokedUrlCommand*)command
    {
        [self.commandDelegate runInBackground:^{
            NSDictionary* subtypes = [GalleryAPI subtypes];
            __block NSMutableArray* albums = [[NSMutableArray alloc] init];
            __block NSDictionary* cameraRoll;

            NSArray* collectionTypes = @[
                                         @{ @"title" : @"smart",
                                            @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeSmartAlbum] },
                                         @{ @"title" : @"album",
                                            @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum] }
                                         ];

            for (NSDictionary* collectionType in collectionTypes) {
                
                
                [[PHAssetCollection fetchAssetCollectionsWithType:[collectionType[@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                                        
                    if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil &&
                        ([subtypes.allKeys indexOfObject:@(collection.assetCollectionSubtype)] != NSNotFound)) {
                        
                        PHFetchResult* result = [PHAsset fetchAssetsInAssetCollection:collection
                                                                              options:nil];
                        
//                        PHAsset *firstAsset = [result firstObject];
//                        NSLog(@"%@",firstAsset);
                        
                        // skip empty ablums
                        if (result.count > 0) {
                            
                            if ([collection.localizedTitle isEqualToString:@"Camera Roll"] && collection.assetCollectionType == PHAssetCollectionTypeSmartAlbum) {
                                    cameraRoll = @{
                                       @"id" : collection.localIdentifier,
                                       @"title" : collection.localizedTitle,
                                       @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                       @"origType" : [collection valueForKey:@"assetCollectionSubtype"],
                                       @"assetsCount" : [NSString stringWithFormat:@"%d", (int)result.count],
                                    };
                            }
                            else {
                                
                                [albums addObject:@{
                                    @"id" : collection.localIdentifier,
                                    @"title" : collection.localizedTitle,
                                    @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                    @"origType" : [collection valueForKey:@"assetCollectionSubtype"],
                                    @"assetsCount" : [NSString stringWithFormat:@"%d", (int)result.count]
                                }];
                            }
                        }
                    }
                }];
            }

            if (cameraRoll)
                [albums insertObject:cameraRoll atIndex:0];

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:albums];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }

    - (void)getMedia:(CDVInvokedUrlCommand*)command
    {
        [self.commandDelegate runInBackground:^{
            NSDictionary* subtypes = [GalleryAPI subtypes];
            NSDictionary* album = [command argumentAtIndex:0];
            __block NSMutableArray* assets = [[NSMutableArray alloc] init];
            __block PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
            options.synchronous = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.networkAccessAllowed = true;

            PHFetchResult* collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[ album[@"id"] ]
                                                                                              options:nil];

            if (collections && collections.count > 0) {
                PHAssetCollection* collection = collections[0];
                [[PHAsset fetchAssetsInAssetCollection:collection
                                               options:nil] enumerateObjectsUsingBlock:^(PHAsset* obj, NSUInteger idx, BOOL* stop) {
                    //if (obj.mediaType == PHAssetMediaTypeImage)
                        NSLog(@"%@",obj);
                        [assets addObject:@{
                                            @"id" : obj.localIdentifier,
                                            @"title" : @"",
                                            @"orientation" : @"up",
                                            @"lat" : @4,
                                            @"lng" : @5,
                                            @"width" : [NSNumber numberWithFloat:obj.pixelWidth],
                                            @"height" : [NSNumber numberWithFloat:obj.pixelHeight],
                                            @"size" : @0,
                                            @"created" : [NSNumber numberWithDouble:obj.creationDate.timeIntervalSince1970],
                                            @"duration" : [NSNumber numberWithDouble:obj.duration],
                                            @"data" : @"",
                                            @"thumbnail" : @"",
                                            @"error" : @"false",
                                            @"extension" : [obj valueForKey:@"uniformTypeIdentifier"],
                                            @"filename" : [obj valueForKey:@"filename"],
                                            @"type" : subtypes[@(collection.assetCollectionSubtype)]
                                            }];
                }];
            }

            NSArray* reversedAssests = [[assets reverseObjectEnumerator] allObjects];

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:reversedAssests];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }

    - (void)getMediaThumbnail:(CDVInvokedUrlCommand*)command
    {
        // Check command.arguments here.
        [self.commandDelegate runInBackground:^{

            PHImageRequestOptions* options = [PHImageRequestOptions new];
            options.synchronous = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.networkAccessAllowed = true;

            NSMutableDictionary* media = [command argumentAtIndex:0];

            NSString* imageId = [media[@"id"] stringByReplacingOccurrencesOfString:@"/" withString:@"^"];
            NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
            NSString* thumbnailPath = [NSString stringWithFormat:@"%@/%@_mthumb.png", docsPath, imageId];

            NSFileManager* fileMgr = [[NSFileManager alloc] init];

            media[@"thumbnail"] = thumbnailPath;
            if ([fileMgr fileExistsAtPath:thumbnailPath])
                NSLog(@"file exist");
            else {
                NSLog(@"file doesn't exist");
                media[@"error"] = @"true";

                PHFetchResult* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[ media[@"id"] ]
                                                                         options:nil];
                if (assets && assets.count > 0) {
                    [[PHImageManager defaultManager] requestImageForAsset:assets[0]
                                                               targetSize:CGSizeMake(300, 300)
                                                              contentMode:PHImageContentModeAspectFill
                                                                  options:options
                                                            resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                                if (result) {
                                                                    NSError* err = nil;
                                                                    if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                              options:NSAtomicWrite
                                                                                                                error:&err])
                                                                        media[@"error"] = @"false";
                                                                    else {
                                                                        if (err) {
                                                                            media[@"thumbnail"] = @"";
                                                                            NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                        }
                                                                    }
                                                                }
                                                            }];
                }
                else {
                    if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {

                        [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                  subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                                  options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                            if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil) {
                                [[PHAsset fetchAssetsInAssetCollection:collection
                                                               options:nil] enumerateObjectsUsingBlock:^(PHAsset* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                                    if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                        [[PHImageManager defaultManager] requestImageForAsset:obj
                                                                                   targetSize:CGSizeMake(300, 300)
                                                                                  contentMode:PHImageContentModeAspectFill
                                                                                      options:options
                                                                                resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                                                    if (result) {
                                                                                        NSError* err = nil;
                                                                                        if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                                                  options:NSAtomicWrite
                                                                                                                                    error:&err])
                                                                                            media[@"error"] = @"false";
                                                                                        else {
                                                                                            if (err) {
                                                                                                media[@"thumbnail"] = @"";
                                                                                                NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }];
                                    }
                                }];
                            }
                        }];
                    }
                }
            }

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:media];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }

    - (void)getHQImageData:(CDVInvokedUrlCommand*)command
    {
        [self.commandDelegate runInBackground:^{

            PHImageRequestOptions* options = [PHImageRequestOptions new];
            options.synchronous = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeNone;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.networkAccessAllowed = true;

            NSString* mediaURL = nil;
            NSNumber* mediaDuration = 0;
            
            BOOL isVideo = false;

            NSMutableDictionary* media = [command argumentAtIndex:0];
            
            mediaDuration = media[@"duration"];

            NSString* docsPath = [[NSTemporaryDirectory() stringByStandardizingPath] stringByAppendingPathComponent:kDirectoryName];
            NSError* error;

            NSFileManager* fileMgr = [NSFileManager new];

            BOOL canCreateDirectory = false;

            if (![fileMgr fileExistsAtPath:docsPath])
                canCreateDirectory = true;

            BOOL canWriteFile = true;

            if (canCreateDirectory) {
                if (![[NSFileManager defaultManager] createDirectoryAtPath:docsPath
                                               withIntermediateDirectories:NO
                                                                attributes:nil
                                                                     error:&error]) {
                    NSLog(@"Create directory error: %@", error);
                    canWriteFile = false;
                }
            }
            
            NSLog(@"MEdia ITEM: %@", media );
            NSLog(@"MEdia DURATION: %@", media[@"duration"] );
            if([mediaDuration isEqualToNumber:[NSNumber numberWithInt:0]]){
                //NSLog(@"MEdia IS PHOTO! ");
            }else{
                isVideo = true;
            }

            if (canWriteFile) {
                //NSString* imageId = [media[@"id"] stringByReplacingOccurrencesOfString:@"/" withString:@"^"];
                //NSString* imagePath = [NSString stringWithFormat:@"%@/%@.jpg", docsPath, imageId];
                NSString* imagePath = [NSString stringWithFormat:@"%@/%@", docsPath, media[@"savefilename"]];
                
                // replace HEIC with jpg
                imagePath = [imagePath stringByReplacingOccurrencesOfString:@"HEIC" withString:@"jpg"];
                imagePath = [imagePath stringByReplacingOccurrencesOfString:@"heic" withString:@"jpg"];

                
                //                NSString* imagePath = [NSString stringWithFormat:@"%@/temp.png", docsPath];

                __block NSData* mediaData;
                __block NSURL *videoURL;
                mediaURL = imagePath;

                PHFetchResult* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[ media[@"id"] ]
                                                                         options:nil];
                PHContentEditingInputRequestOptions *editOptions = [[PHContentEditingInputRequestOptions alloc] init];

                [assets[0] requestContentEditingInputWithOptions:editOptions completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {

                    if (contentEditingInput.fullSizeImageURL) {
                        NSLog(@"MEdia URL: %@", contentEditingInput.fullSizeImageURL);
                        //do something with contentEditingInput.fullSizeImageURL
                    }

                }];
                
                if(isVideo){
                    
                    NSLog(@"IS VIDEO!!!");
                    
                    
                    dispatch_group_t group = dispatch_group_create();
                    dispatch_group_enter(group);
    
                    [[PHImageManager defaultManager] requestAVAssetForVideo:assets[0] options:nil resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
    
                        if ([asset isKindOfClass:[AVURLAsset class]]) {
                            NSURL *url = [(AVURLAsset *)asset URL];
                            NSLog(@"Final URL %@",url);
                            NSData *videoData = [NSData dataWithContentsOfURL:url];
    
                            // optionally, write the video to the temp directory
//                            NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.mp4",[NSDate timeIntervalSinceReferenceDate]]];
    
                            videoURL = [NSURL fileURLWithPath:imagePath];
                            BOOL writeResult = [videoData writeToURL:videoURL atomically:true];
    
                            if(writeResult) {
                                NSLog(@"video success");
                            }
                            else {
                                NSLog(@"video failure");
                            }
                             dispatch_group_leave(group);
                            // use URL to get file content
                        }
                    }];
                    dispatch_group_wait(group,  DISPATCH_TIME_FOREVER);
                
                }else{

                
                    if (assets && assets.count > 0) {
                        [[PHImageManager defaultManager] requestImageDataForAsset:assets[0]
                                                                          options:options
                                                                    resultHandler:^(NSData* _Nullable imageData, NSString* _Nullable dataUTI, UIImageOrientation orientation, NSDictionary* _Nullable info) {
                                                                        NSLog(@"ImageData: %@", imageData);
                                                                        if (imageData) {
                                                                            NSLog(@"MEdia URL: %@", imageData);
                                                                            //                                                                Processing Image Data if needed
                                                                            // Image must always be converted to JPEG to avoid reading HEIC files
                                                                            UIImage* image = [UIImage imageWithData:imageData];
                                                                            if (orientation != UIImageOrientationUp) {
                                                                                image = [self fixrotation:image];
                                                                            }
                                                                            mediaData = UIImageJPEGRepresentation(image, 1);

                                                                            //writing image to a file
                                                                            NSError* err = nil;
                                                                            if ([mediaData writeToFile:imagePath
                                                                                               options:NSAtomicWrite
                                                                                                 error:&err]) {
                                                                                //                                                                    media[@"error"] = @"false";
                                                                            }
                                                                            else {
                                                                                if (err) {
                                                                                    //                                                                        media[@"thumbnail"] = @"";
                                                                                    NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                }
                                                                            }
                                                                        } else {
                                                                            @autoreleasepool {
                                                                                PHAsset *asset = assets[0];
                                                                                [[PHImageManager defaultManager] requestImageForAsset:asset
                                                                                                                           targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                                                                                                                          contentMode:PHImageContentModeAspectFit
                                                                                                                              options:options
                                                                                                                        resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                                                                                            if (result)
                                                                                                                                mediaData =UIImageJPEGRepresentation(result, 1);
                                                                                                                            NSError* err = nil;
                                                                                                                            if ([mediaData writeToFile:imagePath
                                                                                                                                               options:NSAtomicWrite
                                                                                                                                                 error:&err]) {
                                                                                                                                //                                                                    media[@"error"] = @"false";
                                                                                                                            }
                                                                                                                            else {
                                                                                                                                if (err) {
                                                                                                                                    //                                                                        media[@"thumbnail"] = @"";
                                                                                                                                    NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }];
                                                                            };
                                                                        }
                                                                    }];

                    } else {
                        if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {

                            [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                      subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                                      options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                                if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil) {
                                    [[PHAsset fetchAssetsInAssetCollection:collection
                                                                   options:nil] enumerateObjectsUsingBlock:^(PHAsset* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                                        if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                            [[PHImageManager defaultManager] requestImageDataForAsset:obj
                                                                                              options:options
                                                                                        resultHandler:^(NSData* _Nullable imageData, NSString* _Nullable dataUTI, UIImageOrientation orientation, NSDictionary* _Nullable info) {
                                                                                            if (imageData) {
                                                                                                //                                                                Processing Image Data if needed
                                                                                                // Image must always be converted to JPEG to avoid reading HEIC files
                                                                                                UIImage* image = [UIImage imageWithData:imageData];
                                                                                                if (orientation != UIImageOrientationUp) {
                                                                                                    image = [self fixrotation:image];
                                                                                                }
                                                                                                mediaData = UIImageJPEGRepresentation(image, 1);

                                                                                                //writing image to a file
                                                                                                NSError* err = nil;
                                                                                                if ([mediaData writeToFile:imagePath
                                                                                                                   options:NSAtomicWrite
                                                                                                                     error:&err]) {
                                                                                                    //                                                                    media[@"error"] = @"false";
                                                                                                }
                                                                                                else {
                                                                                                    if (err) {
                                                                                                        //                                                                        media[@"thumbnail"] = @"";
                                                                                                        NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }];
                                        }
                                    }];
                                }
                            }];
                        }
                    }
                }
                
            }; // isVideo

            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:mediaURL ? CDVCommandStatus_OK : CDVCommandStatus_ERROR
                                                              messageAsString:mediaURL];

            [self.commandDelegate sendPluginResult:pluginResult
                                        callbackId:command.callbackId];
        }];
    }

    + (NSDictionary*)subtypes
    {
        NSDictionary* subtypes = @{ @(PHAssetCollectionSubtypeAlbumRegular) : @"PHAssetCollectionSubtypeAlbumRegular",
                                    @(PHAssetCollectionSubtypeAlbumImported) : @"PHAssetCollectionSubtypeAlbumImported",
                                    @(PHAssetCollectionSubtypeAlbumMyPhotoStream) : @"PHAssetCollectionSubtypeAlbumMyPhotoStream",
                                    @(PHAssetCollectionSubtypeAlbumCloudShared) : @"PHAssetCollectionSubtypeAlbumCloudShared",
                                    @(PHAssetCollectionSubtypeSmartAlbumFavorites) : @"PHAssetCollectionSubtypeSmartAlbumFavorites",
                                    @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded) : @"PHAssetCollectionSubtypeSmartAlbumRecentlyAdded",
                                    @(PHAssetCollectionSubtypeSmartAlbumUserLibrary) : @"PHAssetCollectionSubtypeSmartAlbumUserLibrary",
                                    @(PHAssetCollectionSubtypeSmartAlbumSelfPortraits) : @"PHAssetCollectionSubtypeSmartAlbumSelfPortraits",
                                    @(PHAssetCollectionSubtypeSmartAlbumScreenshots) : @"PHAssetCollectionSubtypeSmartAlbumScreenshots",
                                    };
        return subtypes;
    }

    - (UIImage*)fixrotation:(UIImage*)image
    {

        if (image.imageOrientation == UIImageOrientationUp)
            return image;
        CGAffineTransform transform = CGAffineTransformIdentity;

        switch (image.imageOrientation) {
            case UIImageOrientationDown:
            case UIImageOrientationDownMirrored:
                transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
                transform = CGAffineTransformRotate(transform, M_PI);
                break;

            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
                transform = CGAffineTransformTranslate(transform, image.size.width, 0);
                transform = CGAffineTransformRotate(transform, M_PI_2);
                break;

            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                transform = CGAffineTransformTranslate(transform, 0, image.size.height);
                transform = CGAffineTransformRotate(transform, -M_PI_2);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationUpMirrored:
                break;
        }

        switch (image.imageOrientation) {
            case UIImageOrientationUpMirrored:
            case UIImageOrientationDownMirrored:
                transform = CGAffineTransformTranslate(transform, image.size.width, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
                break;

            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRightMirrored:
                transform = CGAffineTransformTranslate(transform, image.size.height, 0);
                transform = CGAffineTransformScale(transform, -1, 1);
                break;
            case UIImageOrientationUp:
            case UIImageOrientationDown:
            case UIImageOrientationLeft:
            case UIImageOrientationRight:
                break;
        }

        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                                 CGImageGetBitsPerComponent(image.CGImage), 0,
                                                 CGImageGetColorSpace(image.CGImage),
                                                 CGImageGetBitmapInfo(image.CGImage));
        CGContextConcatCTM(ctx, transform);
        switch (image.imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                // Grr...
                CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
                break;

            default:
                CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
                break;
        }

        // And now we just create a new UIImage from the drawing context
        CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
        UIImage* img = [UIImage imageWithCGImage:cgimg];
        CGContextRelease(ctx);
        CGImageRelease(cgimg);
        return img;
    }

    + (NSString*)cordovaVersion
    {
        return CDV_VERSION;
    }

    @end
