# ContestJudging - On-Chain Hackathon Judging System

A transparent, tamper-proof coding contest judging system built on the Ethereum blockchain. This project enables hackathon organizers to manage participant registration, judge assignments, scoring, and final ranking entirely on-chain.

## Overview

Traditional hackathon judging systems suffer from several problems:
- Centralized control allowing manipulation of scores
- Lack of transparency in the scoring process
- No immutable record of judging decisions
- Manual calculation prone to errors

This project solves these problems by implementing a smart contract that:
- Stores all scores immutably on the blockchain
- Automatically calculates final rankings
- Provides complete transparency - anyone can verify scores
- Eliminates manual intervention in score calculation

## Use Cases

This transparent judging system is critically needed in various scenarios:

### 1. University Hackathons
PES University and other institutions conduct annual hackathons with hundreds of students. Transparent scoring builds trust and encourages participation. Immutability ensures no allegations of favoritism.

### 2. National Coding Olympiads
Large-scale competitive programming events with multiple judges evaluating thousands of submissions. On-chain leaderboard provides instant public verification and eliminates manual score compilation errors.

### 3. Scholarship Merit Evaluation Committees
Academic institutions award scholarships based on coding tests evaluated by multiple committee members. Transparent aggregation prevents disputes and provides immutable records for audit purposes.

### 4. Internal Company Coding Challenges
Tech companies run internal hackathons where fair evaluation builds employee trust. No manipulation of results is possible.

### 5. Open Source Project Contests
GitHub-sponsored coding competitions with global participants. Public verification ensures fairness and trust.

## Project Structure

```
BC_proj/
├── ContestJudging.sol     # Solidity smart contract
├── index_pes_fixed.html   # Frontend web interface
├── package.json           # Node.js dependencies
├── .gitignore             # Git ignore rules
└── node_modules/          # Installed dependencies
```

## Technology Stack

### Blockchain Layer
- **Solidity**: Smart contract development (version 0.8.19)
- **Ethereum**: Blockchain platform for deployment
- **Gas Optimization**: Implemented using view functions, memory optimization

### Frontend Layer
- **HTML5/CSS3**: User interface
- **JavaScript**: Client-side logic
- **Web3.js (v1.10.0)**: Ethereum blockchain interaction
- **MetaMask**: Wallet connection for users

### Development Tools
- **Node.js**: Package management
- **npm**: Dependency management

## Contract Architecture

### Contest States
The contest follows a three-phase lifecycle:

1. **REGISTRATION**: Organizer registers participants and judges, assigns participants to judges
2. **ACTIVE**: Judges submit scores for their assigned participants
3. **FINALIZED**: Contest is closed, rankings are calculated and locked

### Data Structures

#### Structs

```solidity
struct Score {
    uint8   problemSolving;  // Max 40 points
    uint8   codeQuality;     // Max 35 points
    uint8   efficiency;      // Max 25 points
    uint16  aggregate;       // Sum of all scores
    bool    submitted;       // Whether score is submitted
    uint256 timestamp;       // Time of submission
}

struct Judge {
    address wallet;          // Ethereum address
    string  name;            // Judge's name
    bool    registered;      // Registration status
    uint256 submittedCount;  // Number of scores submitted
    uint256 assignedCount;   // Number of participants assigned
}

struct Participant {
    address wallet;          // Ethereum address
    string  name;            // Participant's name
    bool    registered;      // Registration status
    uint256 totalAggregate;  // Sum of all judge scores
    uint256 judgeCount;      // Number of judges who scored
    uint256 finalScore;      // Average score (totalAggregate / judgeCount)
    uint8   rank;            // Final rank position
}
```

### Key Functions

#### Organizer Functions
- `registerParticipant(address _wallet, string calldata _name)` - Register a participant
- `registerJudge(address _wallet, string calldata _name)` - Register a judge
- `assignParticipantsToJudge(address _judge, address[] calldata _participants)` - Assign participants to a judge
- `startJudging()` - Transition from REGISTRATION to ACTIVE state
- `finalizeContest()` - Transition from ACTIVE to FINALIZED state

#### Judge Functions
- `submitScore(address _participant, uint8 _problemSolving, uint8 _codeQuality, uint8 _efficiency)` - Submit score for a participant

#### View Functions
- `getLeaderboard()` - Returns sorted list of participant addresses
- `getAllParticipants()` - Returns all registered participants
- `getAllJudges()` - Returns all registered judges
- `getScore(address _judge, address _participant)` - Get score details
- `getParticipant(address _wallet)` - Get participant details
- `getJudge(address _wallet)` - Get judge details
- `getJudgingProgress()` - Returns submitted vs required score count
- `isReadyToFinalize()` - Check if all judges have submitted all scores

### Access Control

The contract implements role-based access control:
- **Organizer**: Deploys the contract, has sole authority to register participants/judges, start and finalize contests
- **Judge**: Can only submit scores for their assigned participants
- **Public**: Can view all scores and rankings

### Security Features

1. **Custom Errors**: Reverts with descriptive error messages
2. **State Modifiers**: Prevents actions in incorrect contest states
3. **Validation**: All inputs validated before processing
4. **Immutability**: Organizer address is immutable after deployment

## System Flow

### Phase 1: Registration
```
[Organizer] -> Deploy Contract (sets contest name)
        |
        v
[Organizer] -> Register Participants (one by one)
        |
        v
[Organizer] -> Register Judges (one by one)
        |
        v
[Organizer] -> Assign Participants to Judges
        |
        v
[Organizer] -> Start Judging (transitions to ACTIVE)
```

### Phase 2: Judging
```
[Judge] -> Connect Wallet
        |
        v
[Judge] -> View Assigned Participants
        |
        v
[Judge] -> Submit Score (problemSolving, codeQuality, efficiency)
        |
        v
[Contract] -> Validates and Stores Score
        |
        v
[Repeat] -> Judge submits for all assigned participants
```

### Phase 3: Finalization
```
[Organizer] -> Check Judging Progress
        |
        v
[Organizer] -> Finalize Contest (only when all scores submitted)
        |
        v
[Contract] -> Calculates average scores
        |
        v
[Contract] -> Sorts by final score (bubble sort)
        |
        v
[Contract] -> Assigns ranks
        |
        v
[Finalized] -> Rankings are locked and public
```

## Frontend Interface

The HTML interface provides:

1. **Connect Screen**: Initial screen to connect MetaMask wallet
2. **Header**: Shows contest name, network badge, and connected wallet
3. **Organizer Panel**: Register participants, judges, assign participants, start/finalize contest
4. **Judge Panel**: View assigned participants, submit scores
5. **Leaderboard Panel**: Display final rankings when contest is finalized
6. **Progress Panel**: Show judging progress statistics

### Visual Design
- Dark theme with navy background
- PES University branding (crimson accent colors)
- IBM Plex font family (Mono and Sans)
- Clean, academic aesthetic

## Deployment

### Prerequisites
- Node.js installed
- MetaMask browser extension
- Ganache (local blockchain for testing)
- Remix IDE (for smart contract development)

### Development Environment Setup

#### 1. Ganache Setup
1. Download and install Ganache from https://www.trufflesuite.com/ganache
2. Launch Ganache and create a new workspace
3. Configure network settings:
   - Network Name: Localhost 7545
   - RPC Server: http://127.0.0.1:7545
   - Chain ID: 1337
   - Network ID: 1337

#### 2. Configure MetaMask
1. Open MetaMask browser extension
2. Add a new network:
   - Network Name: Ganache Local
   - New RPC URL: http://127.0.0.1:7545
   - Chain ID: 1337
   - Currency Symbol: ETH
3. Import accounts from Ganache (click "Import Account" and paste private key for 6 accounts)

#### 3. Remix IDE Setup
1. Open Remix IDE at https://remix.ethereum.org
2. Create a new file: `ContestJudging.sol`
3. Copy the contract code and compile using 0.8.19 version
4. Deploy to "Injected Provider - MetaMask" (ensure MetaMask is connected to Ganache)

### Steps
1. Install dependencies:
   ```
   npm install
   ```

2. Deploy the smart contract to Ganache:
   - Use Remix IDE
   - Select "Injected Provider - MetaMask" environment
   - Deploy and confirm via MetaMask
   - Note the deployed contract address

3. Update the frontend (if needed) with the contract address

4. Open `index_pes_fixed.html` in a web browser

5. Connect MetaMask and use the interface

## Testing on Ganache

### Wallet Setup (6 Wallets Required)
The system is tested with exactly 6 wallets as follows:

| Role        | Wallet Number | Purpose                              |
|-------------|---------------|--------------------------------------|
| Organizer   | Wallet 0      | Deploys contract, manages contest   |
| Judge 1     | Wallet 1      | Evaluates assigned participants     |
| Judge 2     | Wallet 2      | Evaluates assigned participants     |
| Participant | Wallet 3      | Competes in the contest             |
| Participant | Wallet 4      | Competes in the contest             |
| Participant | Wallet 5      | Competes in the contest             |

### Test Scenarios

#### Scenario 1: Registration Phase
1. Organizer (Wallet 0) deploys the contract with contest name "PES Hackathon"
2. Organizer registers 3 participants (Wallets 3, 4, 5)
3. Organizer registers 2 judges (Wallets 1, 2)
4. Organizer assigns: Judge 1 -> Participants 1,2; Judge 2 -> Participants 2,3
5. Organizer starts judging (state changes to ACTIVE)

#### Scenario 2: Valid Score Submission
1. Judge 1 (Wallet 1) submits score for assigned Participant 1
2. Judge 1 submits score for assigned Participant 2
3. Judge 2 (Wallet 2) submits score for assigned Participant 2
4. Judge 2 submits score for assigned Participant 3
5. All submissions succeed - contract accepts valid scores

#### Scenario 3: Rejection - Unassigned Participant
**Expected: Transaction Reverts**
- Judge 1 attempts to submit score for Participant 3 (not assigned)
- Contract reverts with error: `ParticipantNotAssigned`
- Score is NOT recorded

#### Scenario 4: Rejection - Double Submission
**Expected: Transaction Reverts**
- Judge 1 attempts to submit again for Participant 1
- Contract reverts with error: `ScoreAlreadySubmitted`
- Original score remains unchanged

#### Scenario 5: Rejection - Invalid Score Values
**Expected: Transaction Reverts**
- Judge attempts to submit problemSolving = 50 (max is 40)
- Contract reverts with error: `InvalidScore("problemSolving", 50, 40)`
- Score is NOT recorded

#### Scenario 6: Rejection - Non-Judge Submitting
**Expected: Transaction Reverts**
- Participant (Wallet 3) attempts to submit a score
- Contract reverts with error: `NotAJudge`

#### Scenario 7: Finalization
1. Organizer checks `isReadyToFinalize()` returns true
2. Organizer calls `finalizeContest()`
3. Contract calculates average scores and sorts leaderboard
4. State changes to FINALIZED - leaderboard is locked

#### Scenario 8: Rejection After Finalization
**Expected: All Transactions Revert**
- Any judge attempts to submit new score -> `ContestNotActive`
- Organizer attempts to register new participant -> `NotInRegistration`
- Any attempt to modify scores -> `AlreadyFinalized`

### Demonstration Checklist
- [ ] Deploy contract with Wallet 0 (Organizer)
- [ ] Register 3 participants with Wallets 3, 4, 5
- [ ] Register 2 judges with Wallets 1, 2
- [ ] Assign participants to judges
- [ ] Start judging phase
- [ ] Judge 1 submits valid scores (2 participants)
- [ ] Judge 2 submits valid scores (2 participants)
- [ ] Demonstrate rejection: Judge 1 tries to score unassigned participant
- [ ] Demonstrate rejection: Judge tries to submit twice for same participant
- [ ] Demonstrate rejection: Invalid score values (> max)
- [ ] Demonstrate rejection: Non-judge (participant) tries to submit
- [ ] Finalize contest as organizer
- [ ] Demonstrate rejection: Any changes after finalization

## Scoring Criteria

The judging system uses three criteria:

| Criterion       | Maximum Points | Description                              |
|-----------------|----------------|------------------------------------------|
| Problem Solving | 40             | Algorithm approach, correctness         |
| Code Quality    | 35             | Readability, structure, best practices  |
| Efficiency      | 25             | Time/space complexity, optimization      |
| **Total**       | **100**        | Maximum possible score                  |

The final score is calculated as the average across all judges:
```
finalScore = totalAggregate / judgeCount
```

## Smart Contract Features Summary

- **Structs**: Participant, Judge, Score data structures
- **Mappings**: Address-based lookups for participants, judges, scores
- **Arrays**: Dynamic arrays for participant list, judge list, ranked participants
- **Enums**: ContestState (REGISTRATION, ACTIVE, FINALIZED)
- **Events**: Emit for all major actions (registration, scoring, finalization)
- **Modifiers**: onlyOrganizer, onlyJudge, inRegistration, inActive
- **Custom Errors**: Revert with specific error messages
- **View Functions**: Read-only functions for transparency
- **Memory vs Storage**: Proper handling of data locations

## Example Usage

1. **Deploy Contract**: Organizer deploys "PES Hackathon 2024"
2. **Register**: Add 20 participants and 5 judges
3. **Assign**: Each judge gets 4 participants to evaluate
4. **Start**: Organizer starts the judging phase
5. **Score**: Each judge submits scores for their participants
6. **Finalize**: Organizer finalizes after all scores are in
7. **View**: Anyone can see the final leaderboard with all scores

## Future Enhancements

- Multi-round contest support
- Category-based judging
- Appeal/review mechanism
- Token-based participation
- Oracle integration for code evaluation



## References

- Solidity Documentation: https://docs.soliditylang.org/
- Web3.js Documentation: https://web3js.readthedocs.io/
- Ethereum Developer Documentation: https://developer.ethereum.org/

---

## Architecture Diagram

```
                    +------------------+
                    |   Organizer     |
                    | (Deploys &      |
                    |  Manages)       |
                    +--------+--------+
                             |
         +-------------------+-------------------+
         |                                       |
         v                                       v
+------------------+                   +------------------+
| Participants    |                   |    Judges        |
| - Register      |                   | - Register       |
| - Submit Code   |                   | - Submit Scores  |
+------------------+                   +------------------+
         |                                       |
         |          +----------------+           |
         +--------->| Smart Contract |<----------+
                    |                |
                    | - Scores       |
                    | - Rankings     |
                    | - State        |
                    +----------------+
                             |
                             v
                    +------------------+
                    |   On-Chain       |
                    |   Ledger         |
                    +------------------+
```

## Images

### Ethereum Blockchain
![Ethereum](https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Ethereum_logo_2014.svg/1200px-Ethereum_logo_2014.svg.png)

### Smart Contract Flow
![Smart Contract](https://tse1.mm.bing.net/th/id/OIP.QdC0yaPpeUVD-cv8oKTj0gHaDP?rs=1&pid=ImgDetMain&o=7&rm=3)

### Blockchain Transparency
![Blockchain Transparency](https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800)

---

*This project demonstrates core Solidity concepts including structs, mappings, arrays, enums, events, modifiers, custom errors, and access control patterns.*
