//
//  GPTJSessionParams.h
//  CameLLM-GPTJ
//
//  Created by Alex Rozanski on 08/06/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("default")))
@interface _GPTJSessionParams : NSObject

@property (nonatomic, readonly, copy) NSString *modelPath;

@property (nonatomic, assign) int32_t numberOfTokens;
@property (nonatomic, assign) int32_t batchSize;

@property (nonatomic, assign) int32_t topK;
@property (nonatomic, assign) float topP;
@property (nonatomic, assign) float temp;
@property (nonatomic, assign) float repeatPenalty;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)defaultParamsWithModelPath:(NSString *)modelPath;

@end

NS_ASSUME_NONNULL_END
