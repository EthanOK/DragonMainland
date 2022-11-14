import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('DragonStakingV1', {
  //   contract: 'DragonStakingV1',
  //   args: ["0x3a70F8292F0053C97c4B394e2fC98389BdE765fb", "0x47879aAC5Dd5979cbAC1EBD305241Fcb54f73afD"],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonStakingV1'];
