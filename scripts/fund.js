const hre = require('hardhat');

async function main() {
  const [owner, feeCollector, operator] = await hre.ethers.getSigners();
  // console.log('OWNER', owner);
  // console.log('FEE COLLECTOR', feeCollector);
  const res = await owner.sendTransaction({
    to: '0x952BA691C09865621DBc50f24Ed0bb0d8324cad7',
    value: hre.ethers.utils.parseEther('1.0'), // Sends exactly 1.0 ether
  });

  const waited = await res.wait();
  const provider = hre.waffle.provider;
  const balanceInWei = await provider.getBalance(
    '0x952BA691C09865621DBc50f24Ed0bb0d8324cad7'
  );

  console.log('RESPONSE', waited);
  console.log('BALANCE', balanceInWei);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
