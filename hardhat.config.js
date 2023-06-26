require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
// const { ACCOUNT_PRIVATE_KEY,ALCHEMY_KEY } = process.env;

module.exports = {
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        runs: 200,
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: 'u',
          },
        },
      },
      viaIR: true,
    },
  },
  // defaultNetwork: "rinkeby",
  paths: {
    artifacts: './client/artifacts',
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    polymain: {
      url: `https://polygon-rpc.com/`,
      accounts: [
        `0x${'ed6890eba286a8e3c4512fa6885d365973b8c54de36f4fbbe536aff78273ddbd'}`,
      ],
    },
    // rinkeby: {
    //   url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_KEY}`,
    //   accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    // }
  },
};
