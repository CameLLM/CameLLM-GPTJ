#ifndef GPTJ_H
#define GPTJ_H

#include <string>
#include <functional>
#include <vector>
#include "llmodel.hh"

class GPTJPrivate;
class GPTJ : public LLModel {
public:
    GPTJ();
    ~GPTJ();

    bool verifyMagic(const std::string &modelPath, NSError **outError) override;

    bool loadModel(const std::string &modelPath) override;
    bool loadModel(const std::string &modelPath, std::istream &fin, NSError **outError) override;
    bool isModelLoaded() const override;
    bool prompt(const std::string &prompt, std::function<bool(const std::string&)> response,
        PromptContext &ctx, int32_t n_predict = 200, int32_t top_k = 50400, float top_p = 1.0f,
        float temp = 0.0f, int32_t n_batch = 9, NSError **outError = nil) override;
    void setThreadCount(int32_t n_threads) override;
    int32_t threadCount() override;

private:
    GPTJPrivate *d_ptr;
};

#endif // GPTJ_H
