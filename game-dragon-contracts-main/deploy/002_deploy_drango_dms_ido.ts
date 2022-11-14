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
  //     "0x9a26e6D24Df036B0b015016D1b55011c19E76C87",
  //     BigNumber.from("1000000000000000000000000"),
  //     "0x75c1227bfB9E006203439B82ED5127f8428fF060"
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonMainlandShardIDO'];
