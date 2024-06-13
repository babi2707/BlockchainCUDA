#ifndef BLOCK_H
#define BLOCK_H

#include <string>

class Block {
private:
    unsigned int index;
    std::string data;
    std::string previousHash;
    time_t timestamp;
    std::string hash;

public:
    Block(unsigned int index, const std::string& data);
    void MineBlock(unsigned int difficulty);
    void SetPreviousHash(const std::string& prevHash) { previousHash = prevHash; }
    std::string GetHash() const { return hash; }
};

extern "C" void MineBlockGPU(uint32_t index, const char* prevHash, time_t tTime, const char* data, uint32_t difficulty, char* result);

#endif // BLOCK_H
