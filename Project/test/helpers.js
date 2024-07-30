const advanceTime = async (time) => {
    await web3.currentProvider.send({
      jsonrpc: "2.0",
      method: "evm_increaseTime",
      params: [time],
      id: new Date().getTime(),
    });
    await web3.currentProvider.send({
      jsonrpc: "2.0",
      method: "evm_mine",
      params: [],
      id: new Date().getTime() + 1,
    });
  };
  
  module.exports = {
    advanceTime,
  };
  