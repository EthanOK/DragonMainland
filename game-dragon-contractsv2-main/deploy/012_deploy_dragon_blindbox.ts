import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0x9390a0d241d5c4D5fB02408512C187c2dac268f7
  // await deploy('DragonBlindbox', {
  //   contract: 'DragonBlindbox',
  //   args: [
  //     "0x70E76c217AF66b6893637FABC1cb2EbEd254C90c",
  //     "0xBD44234387Ecdaf236BEA4E3979Cd2856F03df51",
  //     ["0xbCB428268DF6a25617513c0555d06e1e3809bCF3"],
  //     ["0x6b41db2D9F3eE5d000fC8e810D74a3e9De2C6ed9"],
  //     "0xbCB428268DF6a25617513c0555d06e1e3809bCF3"
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonBlindbox'];

// 1) 龙骨1155合约分配权限 1155 => 盲盒合约 (mint)
// 2）recipient 授权 dms 提币
