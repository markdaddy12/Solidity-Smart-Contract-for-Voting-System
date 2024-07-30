// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    address election_authority;

    struct Candidate {
        string name;
        string partyName;
        string city;
        uint256 voteCount;
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        bool hasPaidTax;
        uint256[] votePreference;
    }

    Candidate[] public candidates;
    mapping(address => Voter) public voters;
    mapping(address => bytes32) private votes;

    uint256 public registerBy;
    uint256 public voteBy;
    uint256 public revealVoteBy;
    uint256 public votingTax;
    string public winnerCandidate;

    event VoteCast(address indexed voter, uint256[] votePreference);
    event VoteRevealed(address indexed voter, uint256[] votePreference);
    event WinnerDetermined(string winner);

    constructor(
        string[] memory _candidateNames,
        string[] memory _partyNames,
        string[] memory _cities
    ) {
        require(
            _candidateNames.length == _partyNames.length &&
                _candidateNames.length == _cities.length,
            "Input lengths do not match"
        );

        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidates.push(
                Candidate({
                    name: _candidateNames[i],
                    partyName: _partyNames[i],
                    city: _cities[i],
                    voteCount: 0
                })
            );
        }

        election_authority = msg.sender;
    }

    modifier onlyElection_authority() {
        require(
            msg.sender == election_authority,
            "Only Election Authority can perform this action"
        );
        _;
    }

    function setRegisterBy(uint256 _timeInMinutes)
        public
        onlyElection_authority
    {
        //Enter time in mintues
        registerBy = block.timestamp + _timeInMinutes;
    }

    function setVoteBy(uint256 _timeInMinutes) public onlyElection_authority {
        //Enter time in mintues
        voteBy = block.timestamp + _timeInMinutes;
    }

    function setRevealVoteBy(uint256 _timeInMinutes)
        public
        onlyElection_authority
    {
        //Enter time in mintues
        revealVoteBy = block.timestamp + _timeInMinutes;
    }

    function register_Voter(address _voter) public onlyElection_authority {
        require(
            block.timestamp <= registerBy,
            "Registration deadline has passed"
        );
        voters[_voter].isRegistered = true;
    }

    function setVotingTax(uint256 _amount) public onlyElection_authority {
        require(
            block.timestamp <= registerBy,
            "Registration deadline has passed"
        );
        votingTax = _amount;
    }

    function register_candidate(
        string memory _name,
        string memory _partyName,
        string memory _city
    ) public onlyElection_authority {
        candidates.push(
            Candidate({
                name: _name,
                partyName: _partyName,
                city: _city,
                voteCount: 0
            })
        );
    }

    function blindedVote(bytes32 _blindedVote) public payable {
        require(
            voters[msg.sender].isRegistered,
            "Only registered voters can vote"
        );
        require(block.timestamp > registerBy, "Voting has not started yet");
        require(block.timestamp <= voteBy, "Voting has ended");
        require(msg.value >= votingTax, "Voting tax not fully paid");

        // Refund excess amount
        if (msg.value > votingTax) {
            payable(msg.sender).transfer(msg.value - votingTax);
        }

        // Store the blinded vote
        votes[msg.sender] = _blindedVote;

        emit VoteCast(msg.sender, voters[msg.sender].votePreference);
    }
    
    function castVote(uint256[] memory _votePreference) public {
        require(
            voters[msg.sender].isRegistered,
            "Only registered voters can vote"
        );
        require(block.timestamp > registerBy, "Voting has not started yet");
        require(block.timestamp <= voteBy, "Voting has ended");
        require(
            _votePreference.length == candidates.length,
            "Vote does not include all candidates"
        );

        // Check if all numbers from 1 to n are present
        bool[] memory isPresent = new bool[](candidates.length);
        for (uint256 i = 0; i < _votePreference.length; i++) {
            require(
                _votePreference[i] > 0 &&
                    _votePreference[i] <= candidates.length,
                "Invalid candidate number in vote"
            );
            require(
                !isPresent[_votePreference[i] - 1],
                "Duplicate candidate number in vote"
            );
            isPresent[_votePreference[i] - 1] = true;
        }

        voters[msg.sender].votePreference = _votePreference;
    }

    function unblindVote(uint256[] memory _votePreference) public {
        require(
            voters[msg.sender].isRegistered,
            "Only registered voters can reveal their vote"
        );
        require(block.timestamp > voteBy, "Reveal period has not started yet");
        require(block.timestamp <= revealVoteBy, "Reveal period has ended");
        require(
            _votePreference.length == candidates.length,
            "Vote does not include all candidates"
        );

        // Check if all numbers from 1 to n are present
        bool[] memory isPresent = new bool[](candidates.length);
        for (uint256 i = 0; i < _votePreference.length; i++) {
            require(
                _votePreference[i] > 0 &&
                    _votePreference[i] <= candidates.length,
                "Invalid candidate number in vote"
            );
            require(
                !isPresent[_votePreference[i] - 1],
                "Duplicate candidate number in vote"
            );
            isPresent[_votePreference[i] - 1] = true;
        }

        // Check if the vote being revealed matches the last blinded vote
        require(
            keccak256(abi.encodePacked(_votePreference)) == votes[msg.sender],
            "Vote being revealed does not match the last blinded vote"
        );

        // If all checks pass, update the voter's vote preference
        voters[msg.sender].votePreference = _votePreference;

        // Update the vote count of the preferred candidate
        candidates[_votePreference[0]].voteCount++;

        emit VoteRevealed(msg.sender, _votePreference);
    }

    function countVotes() public onlyElection_authority {
        require(
            block.timestamp > revealVoteBy,
            "Counting period has not started yet"
        );

        // Initialize a variable to keep track of the winning candidate
        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;

        // Iterate over all candidates
        for (uint256 i = 0; i < candidates.length; i++) {
            // Check if the current candidate has more votes than the current winner
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        // Set the winner candidate
        winnerCandidate = candidates[winningCandidateIndex].name;

        emit WinnerDetermined(winnerCandidate);
    }

    function winner() public view returns (string memory) {
        require(
            block.timestamp > revealVoteBy,
            "Counting period has not ended yet"
        );
        return winnerCandidate;
    }
}