//
//  GPT4AllContext+Internal.h
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

#import <Foundation/Foundation.h>

#include "llmodel.hh"

@interface GPTJContext ()

@property (nonatomic, readonly, assign) LLModel *gptJ;
@property (nonatomic, readonly, assign) LLModel::PromptContext *promptContext;

- (instancetype)initWithGPTJ:(LLModel *)gptJ promptContext:(LLModel::PromptContext *)promptContext;

@end
