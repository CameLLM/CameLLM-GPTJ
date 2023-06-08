//
//  GPTJPredictOperation.m
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

@import CameLLMObjCxx;
@import CameLLMCommonObjCxx;
@import CameLLMPluginHarnessObjCxx;

#import <Foundation/Foundation.h>

#import "GPTJPredictOperation.h"
#import "GPTJContext.h"
#import "GPTJContext+Internal.hh"
#import "GPTJSessionParams.h"

#include <functional>
#include "gptj.hh"

@interface GPTJPredictOperation () {
  GPTJContext *_context;
  NSString *_prompt;
  GPTJPredictOperationEventHandler _eventHandler;
}

@end

@implementation GPTJPredictOperation

- (instancetype)initWithIdentifier:(NSString *)identifier
                           context:(GPTJContext *)context
                            prompt:(NSString *)prompt
                      eventHandler:(GPTJPredictOperationEventHandler)eventHandler;
{
  if ((self = [super init])) {
    _identifier = [identifier copy];
    _context = context;
    _prompt = [prompt copy];
    _eventHandler = [eventHandler copy];
  }

  return self;
}

- (void)main
{
  [self _postEvent:[_CameLLMPredictionEvent started]];

  if ([self _runPrediction]) {
//    [self _postEvent:[_CameLLMPredictionEvent/ updatedSessionContext:[LlamaOperationUtils currentSessionContextWithLlamaContext:_context]]];
    [self _postEvent:self.isCancelled ? [_CameLLMPredictionEvent cancelled] : [_CameLLMPredictionEvent completed]];
  }
}

- (BOOL)_runPrediction
{
  NSMutableString *fullPrompt = [[NSMutableString alloc] init];
  [fullPrompt appendString:@"The prompt below is a question to answer, a task to complete, or a conversation to respond to; decide which and write an appropriate response.\
### Prompt:\n"];
  [fullPrompt appendString:_prompt];

  [fullPrompt appendString:@"\
### Response:\n"];

  const std::string instructPrompt([fullPrompt cStringUsingEncoding:NSUTF8StringEncoding]);

  if (_context.promptContext == nullptr) {
    [self _postEvent:[_CameLLMPredictionEvent failedWithError:makeFailedToPredictErrorWithUnderlyingError(makeCameLLMError(_CameLLMErrorCodeGeneralInternalPredictionFailure, @"promptContext is null"))]];
    return NO;
  }

  std::function<bool (const std::string &)> fn = [self](const std::string &response) -> bool {
    NSString *token = [NSString stringWithCString:response.c_str() encoding:NSUTF8StringEncoding];
    [self _postEvent:[_CameLLMPredictionEvent outputTokenWithToken:token]];
    return !self.isCancelled;
  };

  _context.gptJ->prompt(instructPrompt, fn, *_context.promptContext, _context.params.numberOfTokens, _context.params.topK, _context.params.topP, _context.params.temp, _context.params.batchSize);

  return YES;
}

#pragma mark - Private

- (void)_postEvent:(_CameLLMPredictionEvent *)event
{
  if (_eventHandler != NULL) {
    _eventHandler(event);
  }
}

@end
