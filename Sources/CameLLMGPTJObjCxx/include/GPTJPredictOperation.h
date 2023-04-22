//
//  GPTJPredictOperation.h
//
//
//  Created by Alex Rozanski on 22/04/2023.
//

#import <Foundation/Foundation.h>

@class _CameLLMPredictionEvent;
@class _CameLLMSessionContext;
@class GPTJContext;

NS_ASSUME_NONNULL_BEGIN

typedef void (^GPTJPredictOperationEventHandler)(_CameLLMPredictionEvent *event);

__attribute__((visibility("default")))
@interface GPTJPredictOperation : NSOperation

@property (nonatomic, readonly, copy) NSString *identifier;

- (instancetype)initWithIdentifier:(NSString *)identifier
                           context:(GPTJContext *)context
                            prompt:(NSString *)prompt
                      eventHandler:(GPTJPredictOperationEventHandler)eventHandler;
@end

NS_ASSUME_NONNULL_END
