import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // 0xB559D183b4ab8aED5BAAC9a65DCf9d3a15ec94ab
  // await deploy('DragonBlindbox', {
  //   contract: 'DragonBlindbox',
  //   args: [
  //     "0x9a26e6D24Df036B0b015016D1b55011c19E76C87",
  //     "0xF1a41450f7DDEce82F3ea389E201f3b1478C9893",
  //     ["0xe0C33CD3296ce1cdb3b102afDbaC43d35016954e","0xa82F9F0ABfe82760FacCB1233Bf9d106c4D00716"],
  //     ["0xa82F9F0ABfe82760FacCB1233Bf9d106c4D00716"],
  //     "0x54C3Aaa72632E1CbE6D5eC4e6e4F2D148E438bea"
  //   ],
  //   from: deployer,
  //   log: true,
  // });
};

export default func;

func.tags = ['DragonBlindbox'];

// 1) 龙骨1155合约分配权限 1155 => 盲盒合约 (mint)
// 2）reipent 授权 dms 提币
