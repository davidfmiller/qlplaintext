//
//

#import "FileAttributes.h"


@interface FileAttributes ()

@property (readwrite) BOOL isTextFile;
@property (readwrite) NSString *mimeType;
@property (readwrite) CFStringEncoding fileEncoding;
@property (readwrite) NSURL *url;

@end

@implementation FileAttributes

+ (instancetype)attributesForItemAtURL:(NSURL *)aURL
{
    NSString *magicString = [self magicStringForItemAtURL:aURL];
    if (!magicString)
    {
        return nil;
    }

    // text/x-c; charset=utf-16le
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\S+/\\S+); charset=(\\S+)" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray<NSTextCheckingResult*> *matches = [regex matchesInString:magicString options:NSMatchingAnchored range:NSMakeRange(0, [magicString length])];
    
    if (matches.count == 0 || matches[0].numberOfRanges != 3)
    {
        return nil;
    }

    NSString *mimeType = [magicString substringWithRange:[matches[0] rangeAtIndex: 1]];
    NSString *charset = [magicString substringWithRange:[matches[0] rangeAtIndex: 2]];
    
    CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charset);

    FileAttributes *attributes = [FileAttributes new];
    attributes.fileEncoding = encoding;
    attributes.isTextFile = [self mimeTypeIsTextual:mimeType];
    attributes.mimeType = mimeType;
    attributes.url = aURL;

    return attributes;
}

////////////////////////////////////////////////////////////////////////////////
// Private Methods
////////////////////////////////////////////////////////////////////////////////

+ (NSString *)magicStringForItemAtURL:(NSURL *)aURL
{
    NSString *path = [aURL path];
    NSParameterAssert(path);

    NSMutableDictionary *environment = [NSProcessInfo.processInfo.environment mutableCopy];
    environment[@"LC_ALL"] = @"en_US.UTF-8";

    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/bin/file";
    task.arguments = @[@"--mime", @"--brief", path];
    task.environment = environment;
    task.standardOutput = [NSPipe new];

    [task launch];

    NSData *output = [[task.standardOutput fileHandleForReading] readDataToEndOfFile];

    [task waitUntilExit];

    if (task.terminationReason != NSTaskTerminationReasonExit || task.terminationStatus != 0)
    {
        return nil;
    }

    NSCharacterSet *whitespaceCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSString *stringOutput = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];

    stringOutput = [stringOutput stringByTrimmingCharactersInSet:whitespaceCharset];

    return stringOutput;
}


/**
 * @return YES if mimeType contains "text", or if the mime type conforms to the
 *         public.text UTI.
 */
+ (BOOL)mimeTypeIsTextual:(NSString *)mimeType
{
    NSArray *components = [mimeType componentsSeparatedByString:@"/"];
    if (components.count != 2)
    {
        return NO;
    }

    if ([components[0] rangeOfString:@"text"].location != NSNotFound)
    {
        return YES;
    }

    NSString *UTType = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(
                                                                               kUTTagClassMIMEType,
                                                                               (__bridge CFStringRef)mimeType,
                                                                               kUTTypeData
                                                                               )
                                         );

    return UTTypeConformsTo((__bridge CFStringRef)UTType, kUTTypeText);
}

@end
