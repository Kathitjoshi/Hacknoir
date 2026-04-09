// SPDX-License-Identifier: MIT
//project
pragma solidity ^0.8.19;

/**
 * @title ContestJudging
 * @notice Transparent, tamper-proof coding contest judging system.
 *
 * Solidity concepts used:
 *   Structs, Mappings, Arrays, Enums, Events, Modifiers,
 *   Custom Errors, Access Control, View functions,
 *   Constructor, Memory vs Storage, Immutable
 */
contract ContestJudging {

    enum ContestState { REGISTRATION, ACTIVE, FINALIZED }

    struct Score {
        uint8   problemSolving;
        uint8   codeQuality;
        uint8   efficiency;
        uint16  aggregate;
        bool    submitted;
        uint256 timestamp;
    }

    struct Judge {
        address wallet;
        string  name;
        bool    registered;
        uint256 submittedCount;
        uint256 assignedCount;
    }

    struct Participant {
        address wallet;
        string  name;
        bool    registered;
        uint256 totalAggregate;
        uint256 judgeCount;
        uint256 finalScore;
        uint8   rank;
    }

    address public immutable organizer;
    ContestState public contestState;
    string  public contestName;
    uint256 public constant MAX_PROBLEM_SOLVING = 40;
    uint256 public constant MAX_CODE_QUALITY     = 35;
    uint256 public constant MAX_EFFICIENCY       = 25;

    address[] public participantList;
    address[] public judgeList;
    address[] public rankedParticipants;

    mapping(address => Participant) public participants;
    mapping(address => Judge)       public judges;
    mapping(address => mapping(address => Score)) public scores;
    mapping(address => address[])   public judgeAssignments;
    mapping(address => mapping(address => bool)) public isAssigned;

    error NotOrganizer();
    error NotAJudge();
    error NotInRegistration();
    error NotInActiveState();
    error AlreadyRegistered();
    error NotRegistered();
    error ParticipantNotAssigned(address judge, address participant);
    error ScoreAlreadySubmitted(address judge, address participant);
    error InvalidScore(string criteria, uint8 given, uint256 max);
    error JudgesHaveIncompleteSubmissions();
    error AlreadyFinalized();
    error ContestNotActive();

    event ContestCreated(address indexed organizer, string contestName, uint256 timestamp);
    event ParticipantRegistered(address indexed participant, string name, uint256 timestamp);
    event JudgeRegistered(address indexed judge, string name, uint256 timestamp);
    event ParticipantAssignedToJudge(address indexed judge, address indexed participant, uint256 timestamp);
    event JudgingStarted(uint256 timestamp);
    event ScoreSubmitted(address indexed judge, address indexed participant, uint8 problemSolving, uint8 codeQuality, uint8 efficiency, uint16 aggregate, uint256 timestamp);
    event ContestFinalized(uint256 timestamp, address topRanked);
    event RankAssigned(address indexed participant, uint8 rank, uint256 finalScore);

    modifier onlyOrganizer() { if (msg.sender != organizer) revert NotOrganizer(); _; }
    modifier onlyJudge()     { if (!judges[msg.sender].registered) revert NotAJudge(); _; }
    modifier inRegistration(){ if (contestState != ContestState.REGISTRATION) revert NotInRegistration(); _; }
    modifier inActive()      { if (contestState != ContestState.ACTIVE) revert NotInActiveState(); _; }
    modifier notFinalized()  { if (contestState == ContestState.FINALIZED) revert AlreadyFinalized(); _; }

    constructor(string memory _contestName) {
        organizer    = msg.sender;
        contestName  = _contestName;
        contestState = ContestState.REGISTRATION;
        emit ContestCreated(msg.sender, _contestName, block.timestamp);
    }

    function registerParticipant(address _wallet, string calldata _name)
        external onlyOrganizer inRegistration
    {
        if (_wallet == address(0)) revert NotRegistered();
        if (participants[_wallet].registered) revert AlreadyRegistered();
        if (judges[_wallet].registered)       revert AlreadyRegistered();
        participants[_wallet] = Participant({
            wallet: _wallet, name: _name, registered: true,
            totalAggregate: 0, judgeCount: 0, finalScore: 0, rank: 0
        });
        participantList.push(_wallet);
        emit ParticipantRegistered(_wallet, _name, block.timestamp);
    }

    function registerJudge(address _wallet, string calldata _name)
        external onlyOrganizer inRegistration
    {
        if (_wallet == address(0)) revert NotRegistered();
        if (judges[_wallet].registered)       revert AlreadyRegistered();
        if (participants[_wallet].registered)  revert AlreadyRegistered();
        if (_wallet == organizer)              revert AlreadyRegistered();
        judges[_wallet] = Judge({
            wallet: _wallet, name: _name, registered: true,
            submittedCount: 0, assignedCount: 0
        });
        judgeList.push(_wallet);
        emit JudgeRegistered(_wallet, _name, block.timestamp);
    }

    function assignParticipantsToJudge(address _judge, address[] calldata _participants)
        external onlyOrganizer inRegistration
    {
        if (!judges[_judge].registered) revert NotAJudge();
        for (uint256 i = 0; i < _participants.length; i++) {
            address p = _participants[i];
            if (!participants[p].registered) revert NotRegistered();
            if (!isAssigned[_judge][p]) {
                isAssigned[_judge][p] = true;
                judgeAssignments[_judge].push(p);
                judges[_judge].assignedCount++;
                emit ParticipantAssignedToJudge(_judge, p, block.timestamp);
            }
        }
    }

    function startJudging() external onlyOrganizer inRegistration {
        require(participantList.length > 0, "No participants");
        require(judgeList.length > 0,       "No judges");
        for (uint256 i = 0; i < judgeList.length; i++) {
            require(judges[judgeList[i]].assignedCount > 0, "All judges need assignments");
        }
        contestState = ContestState.ACTIVE;
        emit JudgingStarted(block.timestamp);
    }

    function finalizeContest() external onlyOrganizer inActive {
        for (uint256 i = 0; i < judgeList.length; i++) {
            address judge = judgeList[i];
            if (judges[judge].submittedCount < judges[judge].assignedCount) {
                revert JudgesHaveIncompleteSubmissions();
            }
        }
        for (uint256 i = 0; i < participantList.length; i++) {
            address p = participantList[i];
            if (participants[p].judgeCount > 0) {
                participants[p].finalScore = participants[p].totalAggregate / participants[p].judgeCount;
            }
            rankedParticipants.push(p);
        }
        _sortLeaderboard();
        for (uint256 i = 0; i < rankedParticipants.length; i++) {
            participants[rankedParticipants[i]].rank = uint8(i + 1);
            emit RankAssigned(rankedParticipants[i], uint8(i+1), participants[rankedParticipants[i]].finalScore);
        }
        contestState = ContestState.FINALIZED;
        emit ContestFinalized(block.timestamp, rankedParticipants[0]);
    }

    function submitScore(
        address _participant,
        uint8   _problemSolving,
        uint8   _codeQuality,
        uint8   _efficiency
    ) external onlyJudge inActive {
        if (!isAssigned[msg.sender][_participant])
            revert ParticipantNotAssigned(msg.sender, _participant);
        if (scores[msg.sender][_participant].submitted)
            revert ScoreAlreadySubmitted(msg.sender, _participant);
        if (_problemSolving > MAX_PROBLEM_SOLVING)
            revert InvalidScore("problemSolving", _problemSolving, MAX_PROBLEM_SOLVING);
        if (_codeQuality > MAX_CODE_QUALITY)
            revert InvalidScore("codeQuality", _codeQuality, MAX_CODE_QUALITY);
        if (_efficiency > MAX_EFFICIENCY)
            revert InvalidScore("efficiency", _efficiency, MAX_EFFICIENCY);

        uint16 aggregate = uint16(_problemSolving) + uint16(_codeQuality) + uint16(_efficiency);
        scores[msg.sender][_participant] = Score({
            problemSolving: _problemSolving, codeQuality: _codeQuality,
            efficiency: _efficiency, aggregate: aggregate,
            submitted: true, timestamp: block.timestamp
        });
        participants[_participant].totalAggregate += aggregate;
        participants[_participant].judgeCount++;
        judges[msg.sender].submittedCount++;
        emit ScoreSubmitted(msg.sender, _participant, _problemSolving, _codeQuality, _efficiency, aggregate, block.timestamp);
    }

    function getLeaderboard()       external view returns (address[] memory) { return rankedParticipants; }
    function getAllParticipants()   external view returns (address[] memory) { return participantList; }
    function getAllJudges()         external view returns (address[] memory) { return judgeList; }
    function getJudgeAssignments(address _judge) external view returns (address[] memory) { return judgeAssignments[_judge]; }

    function getScore(address _judge, address _participant)
        external view returns (uint8, uint8, uint8, uint16, bool, uint256)
    {
        Score memory s = scores[_judge][_participant];
        return (s.problemSolving, s.codeQuality, s.efficiency, s.aggregate, s.submitted, s.timestamp);
    }

    function getParticipant(address _wallet)
        external view returns (string memory, bool, uint256, uint256, uint256, uint8)
    {
        Participant memory p = participants[_wallet];
        return (p.name, p.registered, p.totalAggregate, p.judgeCount, p.finalScore, p.rank);
    }

    function getJudge(address _wallet)
        external view returns (string memory, bool, uint256, uint256)
    {
        Judge memory j = judges[_wallet];
        return (j.name, j.registered, j.submittedCount, j.assignedCount);
    }

    function getJudgingProgress() external view returns (uint256 submitted, uint256 required) {
        for (uint256 i = 0; i < judgeList.length; i++) {
            submitted += judges[judgeList[i]].submittedCount;
            required  += judges[judgeList[i]].assignedCount;
        }
    }

    function isReadyToFinalize() external view returns (bool) {
        if (contestState != ContestState.ACTIVE) return false;
        for (uint256 i = 0; i < judgeList.length; i++) {
            if (judges[judgeList[i]].submittedCount < judges[judgeList[i]].assignedCount) return false;
        }
        return true;
    }

    function getContestStateString() external view returns (string memory) {
        if (contestState == ContestState.REGISTRATION) return "REGISTRATION";
        if (contestState == ContestState.ACTIVE)       return "ACTIVE";
        return "FINALIZED";
    }

    function _sortLeaderboard() internal {
        uint256 n = rankedParticipants.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (participants[rankedParticipants[j]].finalScore < participants[rankedParticipants[j+1]].finalScore) {
                    address temp = rankedParticipants[j];
                    rankedParticipants[j]     = rankedParticipants[j+1];
                    rankedParticipants[j+1]   = temp;
                }
            }
        }
    }
}