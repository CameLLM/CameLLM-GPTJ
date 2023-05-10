//
//  GPTJModelUtils.h
//
//
//  Created by Alex Rozanski on 10/05/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("default")))
@interface _GPTJModelUtils : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

// MARK: - Models

+ (BOOL)validateModelAtURL:(NSURL *)fileURL outError:(NSError **)outError;

@end

NS_ASSUME_NONNULL_END
