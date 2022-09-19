import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xBD44234387Ecdaf236BEA4E3979Cd2856F03df51
  // await deploy('DragonMainlandBone', {
  //   contract: 'DragonMainlandBone',
  //   args: [
  //     ["0xbCB428268DF6a25617513c0555d06e1e3809bCF3"], 
  //     ["0xbCB428268DF6a25617513c0555d06e1e3809bCF3"]
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonMainlandBone'];
