#include "Blockchain.cuh"  // Inclui o cabeçalho da classe Blockchain

// Construtor da classe Blockchain
Blockchain::Blockchain() {
    // Adiciona o bloco gênese à cadeia de blocos
    _vChain.emplace_back(Block(0, "Genesis Block"));
    // Define a dificuldade de mineração
    _nDifficulty = 6;
}

// Função para adicionar um novo bloco à cadeia
void Blockchain::AddBlock(Block bNew) {
    // Define o hash do bloco anterior no novo bloco
    bNew.SetPreviousHash(_GetLastBlock().GetHash());
    // Realiza a mineração do novo bloco com a dificuldade definida
    bNew.MineBlock(_nDifficulty);
    // Adiciona o novo bloco à cadeia
    _vChain.push_back(bNew);
}

// Função para obter o último bloco da cadeia
Block Blockchain::_GetLastBlock() const {
    // Retorna o último bloco da cadeia
    return _vChain.back();
}
