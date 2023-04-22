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

#include "llmodel.hh"
#import "gptj.hh"

#include <fstream>

@interface GPTJSetupOperation () {
}

@end

@implementation GPTJSetupOperation

- (instancetype)initWithModelURL:(NSURL *)modelURL eventHandler:(GPTJSetupOperationEventHandler)eventHandler
{
  if ((self = [super init])) {
    _modelURL = [modelURL copy];
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
  const std::string modelPath([_modelURL.path cStringUsingEncoding:NSUTF8StringEncoding]);
  LLModel *gptJ = new GPTJ;

  NSString *modelName = [_modelURL.lastPathComponent stringByDeletingPathExtension];
  if (modelName.length == 0) {
    modelName = @"";
  }

  const std::string cxxModelName([modelName cStringUsingEncoding:NSUTF8StringEncoding]);
  auto fin = std::ifstream(modelPath, std::ios::binary);

  NSError *loadError = nil;
  gptJ->loadModel(cxxModelName, fin, outError);

  LLModel::PromptContext *promptContext = new LLModel::PromptContext;

  GPTJContext *context = [[GPTJContext alloc] initWithGPTJ:gptJ promptContext:promptContext];

  if (outContext) {
    *outContext = context;
  }

  return YES;
}

@end
