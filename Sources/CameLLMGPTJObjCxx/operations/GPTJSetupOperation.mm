//
//  GPTJSetupOperation.m
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

@import CameLLMCommonObjCxx;

#import "GPTJSetupOperation.h"
#import "GPTJContext.h"
#import "GPTJContext+Internal.hh"
#import "GPTJSessionParams.h"

#include "llmodel.hh"
#import "gptj.hh"

#include <fstream>

@interface GPTJSetupOperation () {
  _GPTJSessionParams *_params;
}

@end

@implementation GPTJSetupOperation

- (instancetype)initWithParams:(_GPTJSessionParams *)params eventHandler:(GPTJSetupOperationEventHandler)eventHandler
{
  if ((self = [super init])) {
    _params = params;
    _eventHandler = [eventHandler copy];
  }

  return self;
}

- (void)main
{
  GPTJContext *context = nil;
  NSError *setUpError = nil;

  if (![self _setUpReturningContext:&context error:&setUpError]) {
    if (_eventHandler) {
      _eventHandler([_CameLLMSetupEvent failedWithError:setUpError]);
    }
  } else {
    _eventHandler([_CameLLMSetupEvent succeededWithContext:context]);
  }
}

- (BOOL)_setUpReturningContext:(GPTJContext **)outContext error:(NSError **)outError
{
  const std::string modelPath([_params.modelPath cStringUsingEncoding:NSUTF8StringEncoding]);
  LLModel *gptJ = new GPTJ;

  NSString *modelName = [_params.modelPath.lastPathComponent stringByDeletingPathExtension];
  if (modelName.length == 0) {
    modelName = @"";
  }

  const std::string cxxModelName([modelName cStringUsingEncoding:NSUTF8StringEncoding]);
  auto fin = std::ifstream(modelPath, std::ios::binary);

  NSError *loadError = nil;
  gptJ->loadModel(cxxModelName, fin, outError);

  LLModel::PromptContext *promptContext = new LLModel::PromptContext;

  GPTJContext *context = [[GPTJContext alloc] initWithGPTJ:gptJ params:_params promptContext:promptContext];

  if (outContext) {
    *outContext = context;
  }

  return YES;
}

@end
