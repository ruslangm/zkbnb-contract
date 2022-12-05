import { HardhatUserConfig } from "hardhat/config";

import "hardhat-tracer"
import '@openzeppelin/hardhat-upgrades'
import 'hardhat-contract-sizer'
import 'hardhat-abi-exporter'
import 'solidity-coverage'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import * as dotenv from 'dotenv'

dotenv.config()

// const getAccounts = (privateKeys: string | undefined): Array<string> => {
//     if (!privateKeys) {
//         return []
//     }

//     const privateKeyArr = privateKeys.split(',')
//     return privateKeyArr
//         .filter((privateKey) => {
//             // Filter empty strings, no empty strings should occupy array positions
//             return privateKey.trim().length > 0
//         })
//         .map((privateKey) => {
//             const tempPrivateKey = privateKey.trim()
//             if (tempPrivateKey.startsWith('0x')) {
//                 return tempPrivateKey
//             }
//             return `0x${tempPrivateKey}`
//         })
// }

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            outputSelection: {
                "*": {
                    "*": ["storageLayout"]
                }
            }
        },
    },
    defaultNetwork: 'hardhat',
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
        },
        local: {
            url: process.env.LOCAL_RPC || "http://127.0.0.1:8545",
            accounts: (process.env.LOCAL_PRIVATE_KEY || '0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1').split(','),
            timeout: 100000,
        },
        BSCTestnet: {
            url: process.env.BSC_TESTNET_RPC || "https://data-seed-prebsc-1-s1.binance.org:8545",
            accounts: (process.env.BSC_TESTNET_PRIVATE_KEY || '0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1').split(','),
            timeout: 300000,
            gas: 15000000
        },
    },
    contractSizer: {
        alphaSort: true,
        disambiguatePaths: false,
        runOnCompile: true,
        strict: true,
    },
    abiExporter: {
        path: './abi',
        clear: true,
        flat: true,
        only: [':Governance$', ':ZkBNB', ':StablePriceOracle'],
        spacing: 2,
    },
}

export default config