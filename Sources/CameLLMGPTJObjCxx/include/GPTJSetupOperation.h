//
//  GPTJSetupOperation.h
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

#import <Foundation/Foundation.h>

@class _CameLLMSetupEvent<ContextType>;
@class GPTJContext;
@class _GPTJSessionParams;
@class _CameLLMSetupEvent;

NS_ASSUME_NONNULL_BEGIN

typedef void (^GPTJSetupOperationEventHandler)(_CameLLMSetupEvent<GPTJContext *> *event);

__attribute__((visibility("default")))
@interface GPTJSetupOperation : NSOperation

@property (nonatomic, readonly, copy) GPTJSetupOperationEventHandler eventHandler;

- (instancetype)initWithParams:(_GPTJSessionParams *)params eventHandler:(GPTJSetupOperationEventHandler)eventHandler;

@end

NS_ASSUME_NONNULL_END
