#include "Blockchain.cuh"
#include <iostream>

int main() {
    Blockchain bChain;

    bChain.AddBlock(Block(1, "Block 1 Data"));
    bChain.AddBlock(Block(2, "Block 2 Data"));
    bChain.AddBlock(Block(3, "Block 3 Data"));

    return 0;
}
