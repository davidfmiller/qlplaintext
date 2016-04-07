//

#import <Foundation/Foundation.h>

@interface FileAttributes : NSObject

+ (instancetype)attributesForItemAtURL:(NSURL *)aURL;

@property (readonly) NSURL *url;

@property (readonly) BOOL isTextFile;
@property (readonly) NSString *mimeType;
@property (readonly) CFStringEncoding fileEncoding;

@end


