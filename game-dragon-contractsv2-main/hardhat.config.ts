import { HardhatUserConfig } from 'hardhat/types';
import 'hardhat-deploy';
import 'hardhat-deploy-ethers';
import 'hardhat-contract-sizer';
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-solhint";
import "hardhat-docgen";
import { node_url, accounts } from './utils/network';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.7',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // https://developer.offchainlabs.com/docs/contract_deployment
    arbitrum: {
      url: 'https://rinkeby.arbitrum.io/rpc',
      gasPrice: 0,
      accounts: accounts('arbitrum')
    },
    // https://docs.polygon.technology/docs/develop/hardhat
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: accounts('matic')
    },
    matictest: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["572b9ffa4ce56bd68b0c1b34a093d5bbd157aa553ed31c14c1e82786d4ac8ebe"]
    },
    rinkeby: {
      url: node_url('rinkeby'),
      accounts: accounts('rinkeby'),
    },
    bsctest: {
      url: node_url('bsctest'),
      accounts: accounts('bsctest'),
    },
    bscmain: {
      url: node_url('bscmain'),
      accounts: accounts('bscmain'),
    },
  },
  namedAccounts: {
    deployer: 0,
    tokenOwner: 1,
  },
  paths: {
    sources: 'contracts',
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    currency: 'CHF',
    gasPrice: 21
  },
  docgen: {
    path: './docgen',
    clear: true,
    runOnCompile: true,
  }
};

export default config;
