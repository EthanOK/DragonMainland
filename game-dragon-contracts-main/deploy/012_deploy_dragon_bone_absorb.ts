import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xA43e849C6df8D3623E8Ec57fE75C9Adf6a484bE1
  // await deploy('DragonBoneAbsorb', {
  //   contract: 'DragonBoneAbsorb',
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonBoneAbsorb'];
