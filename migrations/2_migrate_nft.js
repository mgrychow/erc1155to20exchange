const MgNft = artifacts.require("MgNft");

module.exports = function (deployer) {
  deployer.deploy(MgNft);
};
