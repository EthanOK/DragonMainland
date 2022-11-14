import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('DragonMainlandShardsToken', {
  //   contract: 'DragonMainlandShardsToken',
  //   args: ["0x9e663044473f02b15bA6e88e86a21D94Ac32180a"],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonMainlandShardsToken'];