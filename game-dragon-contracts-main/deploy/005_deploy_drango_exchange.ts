import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('DragonExchange', {
  //   contract: 'DragonExchange',
  //   args: ["0x3a70F8292F0053C97c4B394e2fC98389BdE765fb"],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonExchange'];