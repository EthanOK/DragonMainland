import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xF1a41450f7DDEce82F3ea389E201f3b1478C9893
  await deploy('DragonDevour', {
    contract: 'DragonDevour',
    from: deployer,
    log: true,
  });
};

export default func;

func.tags = ['DragonDevour'];
