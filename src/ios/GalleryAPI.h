#import <Photos/Photos.h>
#import <Cordova/CDVPlugin.h>

@interface GalleryAPI : CDVPlugin

- (void) checkPermission:(CDVInvokedUrlCommand*)command;

- (void) getAlbums:(CDVInvokedUrlCommand*)command;

- (void) getMedia:(CDVInvokedUrlCommand*)command;

- (void) getMediaThumbnail:(CDVInvokedUrlCommand*)command;

- (void) getHQImageData:(CDVInvokedUrlCommand*)command;

- (void) clearHQStorage:(CDVInvokedUrlCommand*)command;

@end
