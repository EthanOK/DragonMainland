import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('PreSaleDragonEgg', {
  //   contract: 'PreSaleDragonEgg',
  //   args: ["0xfEEAf17Ce1DD76fc57bd5F816cc33d375656f3D4", "0xa66dB507f67aAa8601e7339a2B8062bCc423b699"],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['PreSaleDragonEgg'];