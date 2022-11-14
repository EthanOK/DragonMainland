import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xF1a41450f7DDEce82F3ea389E201f3b1478C9893
  // await deploy('DragonMainlandBone', {
  //   contract: 'DragonMainlandBone',
  //   args: [
  //     ["0xe0C33CD3296ce1cdb3b102afDbaC43d35016954e","0xa82F9F0ABfe82760FacCB1233Bf9d106c4D00716"],
  //     ["0xa82F9F0ABfe82760FacCB1233Bf9d106c4D00716"]
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonMainlandBone'];
