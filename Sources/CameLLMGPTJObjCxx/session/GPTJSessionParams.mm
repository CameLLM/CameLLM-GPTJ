//
//  GPTJSessionParams.m
//  CameLLM-GPTJ
//
//  Created by Alex Rozanski on 08/06/2023.
//

#import "GPTJSessionParams.h"

@interface _GPTJSessionParams ()
- (instancetype)initWithModelPath:(NSString *)modelPath;
@end

@implementation _GPTJSessionParams

- (instancetype)initWithModelPath:(NSString *)modelPath
{
  if ((self = [super init])) {
    _modelPath = [modelPath copy];
  }

  return self;
}

+ (instancetype)defaultParamsWithModelPath:(NSString *)modelPath
{
  _GPTJSessionParams *params = [[self alloc] initWithModelPath:modelPath];

  params.numberOfTokens = 200;
  params.batchSize = 9;
  params.topK = 50400;
  params.topP = 1.0f;
  params.temp = 0.0f;
  params.repeatPenalty = 1.3f;
  return params;
}

@end
