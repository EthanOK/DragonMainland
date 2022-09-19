import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { BigNumber } from '@ethersproject/bignumber';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('DragonMainlandShardIDO', {
  //   contract: 'DragonMainlandShardIDO',
  //   args: [
  //     "0x27f789dA7dE6416B9DBEa873e4aa1E72f66a1703",
  //     BigNumber.from("1000000000000000000000000"),
  //     "0x28F4c441bc1F2A45D9FE841247777a90cB1ABB8a"
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonMainlandShardIDO'];
