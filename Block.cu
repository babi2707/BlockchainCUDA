#include "Block.cuh"
#include <cuda_runtime.h>
#include <iostream>
#include <iomanip>  // Para std::hex e std::setw
#include <sstream>  // Para std::stringstream

// Variável global do dispositivo para indicar se a solução foi encontrada
__device__ bool dev_found = false;

// Função dummy para simular o cálculo do SHA-256
__device__ void dummy_sha256(const char *input, char *output)
{
    int inputLength = 0;
    while (input[inputLength] != '\0')
    {
        ++inputLength;
    }

    // Simular o cálculo do hash
    for (int i = 0; i < 64; i++)
    {
        output[i] = (input[i % inputLength] + i) % 256;
    }
    output[64] = '\0';
}

// Função _CalculateHash vazia (não está sendo usada)
__device__ void _CalculateHash(char *output, uint32_t index, const char *prevHash, time_t tTime, const char *data, uint32_t nonce)
{
}

// Função para comparar duas strings no dispositivo
__device__ int dev_strncmp(const char *str1, const char *str2, size_t num)
{
    for (size_t i = 0; i < num; i++)
    {
        if (str1[i] != str2[i])
        {
            return str1[i] - str2[i];
        }
        if (str1[i] == '\0')
        {
            return 0;
        }
    }
    return 0;
}

// Função para copiar uma string no dispositivo
__device__ void dev_strncpy(char *dest, const char *src, size_t num)
{
    for (size_t i = 0; i < num; i++)
    {
        dest[i] = src[i];
        if (src[i] == '\0')
        {
            break;
        }
    }
    if (num > 0)
    {
        dest[num - 1] = '\0';
    }
}

// Kernel de mineração de bloco
__global__ void MineBlockKernel(uint32_t index, const char* prevHash, time_t tTime, const char* data, uint32_t difficulty, char* result) {
    // Calcula o nonce inicial baseado no índice do bloco e da thread
    uint32_t nonce = blockIdx.x * blockDim.x + threadIdx.x;
    char target[65];

    // Prepara a string target de zeros baseada na dificuldade
    for (uint32_t i = 0; i < difficulty; ++i) {
        target[i] = '0';
    }
    target[difficulty] = '\0';
    char hash[65];

    while (!dev_found) {
        // Construir o input para o hash diretamente
        int pos = 0;

        // Copiar prevHash para hash
        for (int i = 0; i < 64 && prevHash[i] != '\0'; ++i) {
            hash[pos++] = prevHash[i];
        }

        // Copiar data para hash
        for (int i = 0; i < 64 && data[i] != '\0'; ++i) {
            hash[pos++] = data[i];
        }

        // Copiar tTime para hash (usando reinterpret_cast para tratar como char*)
        char* tTimeChar = reinterpret_cast<char*>(&tTime);
        for (int i = 0; i < sizeof(time_t); ++i) {
            hash[pos++] = tTimeChar[i];
        }

        // Copiar index para hash (usando reinterpret_cast para tratar como char*)
        char* indexChar = reinterpret_cast<char*>(&index);
        for (int i = 0; i < sizeof(uint32_t); ++i) {
            hash[pos++] = indexChar[i];
        }

        // Copiar nonce para hash (usando reinterpret_cast para tratar como char*)
        char* nonceChar = reinterpret_cast<char*>(&nonce);
        for (int i = 0; i < sizeof(uint32_t); ++i) {
            hash[pos++] = nonceChar[i];
        }

        // Calcular o hash usando dummy_sha256
        dummy_sha256(hash, hash);

        // Verificar se o hash atende à dificuldade
        if (dev_strncmp(hash, target, difficulty) == 0) {
            // Se o hash atende à dificuldade, tenta marcar como encontrado usando atomicExch
            if (atomicExch(reinterpret_cast<unsigned int*>(&dev_found), 1u) == 0) {
                dev_strncpy(result, hash, 64); // Copiar apenas os primeiros 64 caracteres
                result[64] = '\0'; // Garantir que o resultado seja uma string terminada por '\0'
            }
        }
        // Incrementa o nonce para o próximo cálculo
        nonce += gridDim.x * blockDim.x;
    }
}

// Função para chamar o kernel de mineração de bloco na GPU
extern "C" void MineBlockGPU(uint32_t index, const char* prevHash, time_t tTime, const char* data, uint32_t difficulty, char* result) {
    char* dev_result;
    cudaMalloc((void**)&dev_result, 65); // Alocar espaço para 65 caracteres

    // Lançar o kernel com 7 blocos e 12 threads por bloco
    MineBlockKernel<<<7, 12>>>(index, prevHash, tTime, data, difficulty, dev_result);
    cudaDeviceSynchronize(); // Sincronizar a execução do dispositivo

    // Copiar o resultado de volta para a memória do host
    cudaMemcpy(result, dev_result, 65, cudaMemcpyDeviceToHost);

    // Garantir que o resultado seja uma string terminada por '\0'
    result[64] = '\0';

    // Liberar memória do dispositivo
    cudaFree(dev_result);
}

// Implementação da função MineBlock da classe Block
void Block::MineBlock(unsigned int difficulty) {
    char result[65];
    MineBlockGPU(index, previousHash.c_str(), timestamp, data.c_str(), difficulty, result);
    std::cout << "Mining block " << index << "..." << std::endl;

    // Converter o hash binário para uma string hexadecimal
    std::stringstream ss;
    for (int i = 0; i < 32; ++i) {
        ss << std::setw(2) << std::setfill('0') << std::hex << (int)(unsigned char)result[i];
    }
    std::string hexHash = ss.str();

    std::cout << "Block mined: " << hexHash << std::endl;
}

// Definição do construtor de Block
Block::Block(unsigned int index, const std::string &data)
    : index(index), data(data)
{
    this->timestamp = std::time(nullptr);
    this->previousHash = "previous_hash_value";
    this->hash = "";
}
