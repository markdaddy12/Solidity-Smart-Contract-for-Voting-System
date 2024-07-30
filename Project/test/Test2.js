const Voting = artifacts.require("Voting");

contract("Voting", (accounts) => {
  let votingInstance;

  before(async () => {
    // Deploy the contract with initial candidates
    votingInstance = await Voting.new(
      ["PersonA", "PersonB", "PersonC"],
      ["PartyA", "PartyB", "PartyC"],
      ["CityA", "CityB", "CityC"]
    );
  });

  it("should set deadlines and register voters", async () => {
    const electionAuthority = accounts[0];
    const voterAddresses = accounts.slice(1, 16); // 15 voters

    // Set deadlines
    const currentTime = Math.floor(Date.now() / 1000); // current time in seconds
    await votingInstance.setRegisterBy(currentTime + 5 * 60); // 5 minutes from now
    await votingInstance.setVoteBy(currentTime + 10 * 60); // 10 minutes from now
    await votingInstance.setRevealVoteBy(currentTime + 15 * 60); // 15 minutes from now

    // Register voters
    for (let i = 0; i < voterAddresses.length; i++) {
      await votingInstance.register_Voter(voterAddresses[i], { from: electionAuthority });
    }
  });

  it("should set voting tax", async () => {
    const electionAuthority = accounts[0];
    const taxAmount = web3.utils.toWei("0.01", "ether"); // 0.01 ether

    // Set voting tax
    await votingInstance.setVotingTax(taxAmount, { from: electionAuthority });
  });

  it("should register one more candidate", async () => {
    const electionAuthority = accounts[0];

    // Register one more candidate
    await votingInstance.register_candidate("PersonD", "PartyD", "CityD", { from: electionAuthority });
  });

  it("should conduct voting and reveal votes", async () => {
    const electionAuthority = accounts[0];
    const voterAddresses = accounts.slice(1, 16); // 15 voters

    // Set deadlines
    const currentTime = Math.floor(Date.now() / 1000); // current time in seconds
    await votingInstance.setRegisterBy
    (currentTime + 5 * 60); // 5 minutes from now
    await votingInstance.setVoteBy
    (currentTime + 10 * 60); // 10 minutes from now
    await votingInstance.setRevealVoteBy
    (currentTime + 15 * 60); // 15 minutes from now

    // Register voters
    for (let i = 0; i < voterAddresses.length; i++) {
      await votingInstance.register_Voter(voterAddresses[i], { from: electionAuthority });
    }
  });

  it("should count votes and determine a winner", async () => {
    const electionAuthority = accounts[0];
    const voterAddresses = accounts.slice(1, 16); // 15 voters

    // Set deadlines
    const currentTime = Math.floor(Date.now() / 1000); 
    await votingInstance.setRegisterBy(currentTime + 5 * 60); 
    await votingInstance.setVoteBy(currentTime + 10 * 60); 
    await votingInstance.setRevealVoteBy(currentTime + 15 * 60); 
    // Register voters
    for (let i = 0; i < voterAddresses.length; i++) {
      await votingInstance.register_Voter(voterAddresses[i], { from: electionAuthority });
    }
  });
});

// Helper function to advance time and mine a new block
async function advanceTime(time) {
  await new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_increaseTime',
      params: [time], // 5 minutes
      id: new Date().getTime()
    }, (err1) => {
      if (err1) return reject(err1);

      web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: new Date().getTime()
      }, (err2, res) => {
        return err2 ? reject(err2) : resolve(res);
      });
    });
  });
}
