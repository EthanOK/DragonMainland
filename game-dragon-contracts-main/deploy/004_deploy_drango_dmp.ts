import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer, tokenOwner } = await getNamedAccounts();

  // await deploy('DragonMiraclePotionToken', {
  //   contract: 'DragonMiraclePotionToken',
  //   args: ["0xCC3352976ab5C1ba0c8BAb6BDC7Deab64F3748Bf", [
  //     "0x65fB8809B52E3CF37f2E44fd325719BA94dD8B54",
  //     "0xbB42a12c457327C3B26bf04b741E1297Eb80c402",
  //     "0x21550077d7544C68EbaE66092D139D6850fb9fB5",
  //     "0xfE2e6C79c4CF4E83Dd4BEE06D76149697Dee55b9",
  //     "0x774BA3c586CbB1729E2D969d6aE3a93f79161543",
  //     "0x286b41BCAa0ef48B8785515b22C58b587Ad8bEEE",
  //     "0xA3B2218C363f9791ecbff00439B4fd60950df18A",
  //     "0xb2a8F1797504F0d3d037da430F01ac16c42d1987",
  //     "0x5a44E7ec6cd03A965572595a234EF7771fF64413",
  //     "0x0b342dB90FF3Bb50C9C123f8DCe0DABcAE8855e7",
  //     "0x7Eb879C74B09c585dC6C2458fE88C1f01C3C77c7",
  //     "0xA59f22CA72fbe221B7d96fFD83F2ADdC0f66c68e",
  //     "0x169ACddB452A65a405F12eE715EE4f153f23C96D",
  //     "0xebC3028B7d15d8Fe98ae6F9b31DC126fa0218933",
  //     "0xBB45469117eCb8645012284B210501906aF332cF",
  //     "0xAC23F75eFFf7C2d46334E27BC88dbDff3b83fCC1",
  //     "0x57335fcBaAB0081aa1BfEf2f2C47341e2d47909A",
  //     "0xc6434c795726FE0DA1Bc570f8971DD7Af75A5738",
  //     "0x1E87db378A2981D506E0d09C9FfD8498a40D229D",
  //   ]],
  //   from: deployer,
  //   log: true,
  // });
};



export default func;

func.tags = ['DragonMiraclePotionToken'];