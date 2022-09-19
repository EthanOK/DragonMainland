import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xA43e849C6df8D3623E8Ec57fE75C9Adf6a484bE1
  // await deploy('DragonBoneExchange', {
  //   contract: 'DragonBoneExchange',
  //   // args: ["0xb216C7A33E133c985eF4393B28827EA5D1Ec7769", "0xFF32D06991e6642eB9Cdad46981dDd5891C4Fb79"],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonBoneExchange'];
