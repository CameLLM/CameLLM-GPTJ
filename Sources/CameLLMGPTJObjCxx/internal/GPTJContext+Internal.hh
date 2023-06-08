//
//  GPT4AllContext+Internal.h
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

#import <Foundation/Foundation.h>

#include "llmodel.hh"

@class _GPTJSessionParams;

@interface GPTJContext ()

@property (nonatomic, readonly, assign) LLModel *gptJ;
@property (nonatomic, readonly) _GPTJSessionParams *params;
@property (nonatomic, readonly, assign) LLModel::PromptContext *promptContext;

- (instancetype)initWithGPTJ:(LLModel *)gptJ
                      params:(_GPTJSessionParams *)params
               promptContext:(LLModel::PromptContext *)promptContext;

@end
