#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>

#import "FileAttributes.h"


// Generate a preview for the document with the given url
OSStatus GeneratePreviewForURL(void *thisInterface,
                               QLPreviewRequestRef request,
                               CFURLRef url,
                               CFStringRef contentTypeUTI,
                               CFDictionaryRef options) {

    if (QLPreviewRequestIsCancelled(request))
    {
        return noErr;
    }
    
    FileAttributes *attributes = [FileAttributes attributesForItemAtURL:(__bridge NSURL *)url];

    if (!attributes)
    {
        return noErr;
    }

    if (!attributes.isTextFile)
    {
        return noErr;
    }

    if (attributes.fileEncoding == kCFStringEncodingInvalidId)
    {
        return noErr;
    }

    NSDictionary *previewProperties = @{
                                        (NSString *)kQLPreviewPropertyStringEncodingKey : @( attributes.fileEncoding ),
                                        (NSString *)kQLPreviewPropertyWidthKey      : @700,
                                        (NSString *)kQLPreviewPropertyHeightKey     : @800
                                        };
    
    QLPreviewRequestSetURLRepresentation(
                                         request,
                                         url,
                                         kUTTypePlainText,
                                         (__bridge CFDictionaryRef)previewProperties);
    
    return noErr;

}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
