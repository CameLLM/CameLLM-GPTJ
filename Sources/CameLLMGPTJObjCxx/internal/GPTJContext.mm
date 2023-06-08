//
//  GPTJContext.m
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

#import "GPTJContext.h"
#import "GPTJContext+Internal.hh"

#include "llmodel.hh"

@implementation GPTJContext

- (instancetype)initWithGPTJ:(LLModel *)gptJ params:(_GPTJSessionParams *)params promptContext:(LLModel::PromptContext *)promptContext
{
  if ((self = [super init])) {
    _gptJ = gptJ;
    _params = params;
    _promptContext = promptContext;
  }
  return self;
}

- (void)dealloc
{
  delete _gptJ;
  _gptJ = nullptr;

  delete _promptContext;
  _promptContext = nullptr;
}

@end
