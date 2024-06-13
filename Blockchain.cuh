#ifndef BLOCKCHAIN_H
#define BLOCKCHAIN_H

#include <cstdint>
#include <vector>
#include "Block.cuh"

class Blockchain {
public:
    Blockchain();
    void AddBlock(Block bNew); // Removendo o argumento extra numThreads

private:
    uint32_t _nDifficulty;
    std::vector<Block> _vChain;

    Block _GetLastBlock() const;
};

#endif // BLOCKCHAIN_H
