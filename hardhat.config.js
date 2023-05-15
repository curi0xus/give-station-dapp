require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
// const { ACCOUNT_PRIVATE_KEY,ALCHEMY_KEY } = process.env;

module.exports = {
  solidity: '0.8.4',
  // defaultNetwork: "rinkeby",
  paths: {
    artifacts: './client/artifacts',
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    polymain: {
      url: `https://polygon-rpc.com/`,
      accounts: [
        `0x${'b6a567187c05c73c66ebf0540d2757761618f931f0f4f721285ebdf10fa17c98'}`,
      ],
    },
    // rinkeby: {
    //   url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_KEY}`,
    //   accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    // }
  },
};
