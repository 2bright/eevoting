pragma solidity ^0.4.24;

import "./UserRepository.sol";

library VotingFactory {
    function createVoting(bytes32 _content_hash, bytes _content, uint64[8] _params, uint64[2] _time, address _user_repo)
        public
        returns(address)
    {
        return new Voting(msg.sender, _content_hash, _content, _params, _time, _user_repo);
    }
}

contract Voting {
    address owner;
    
    // hash of detail description and options of this voting
    bytes32 content_hash;

    // detail description and options of this voting
    // content_hash is required, but content is optional.
    bytes content;
    
    // total options
    uint64 option_count;
    
    // how many options could one voter select.
    uint64 select_min;
    uint64 select_max;
    
    // If isAnonymous is true, do not record the options that voter selected.
    uint64 isAnonymous;
    
    // If isPublic is true, any user could vote without being added to user_repo.
    uint64 isPublic;
    
    // If multiWinner is false but has multiple winners, then result is no winner.
    uint64 multiWinner;
    
    // if a winner has votes count less than thresholdWinnerVotes, voting has no winner.
    // thresholdWinnerVotes is min percent of winner votes to total votes.
    uint64 thresholdWinnerVotes;
    
    // if total votes count is less than thresholdTotalVotes, voting has no winner.
    // if isPublic is true, thresholdTotalVotes is min count of votes.
    // if isPublic is false, thresholdTotalVotes is min percent of total votes to total users.
    uint64 thresholdTotalVotes;
    
    // allow voting after to_start_time
    // 0 means allow voting after call startVoting
    uint64 to_start_time;
    
    // deny voting after to_end_time
    // 0 means deny voting after call endVoting
    uint64 to_end_time;
    
    // the time deploy this contract
    uint64 create_time;
    
    UserRepository user_repo;
    mapping(address => uint) user_weight_index;
    UserWeight[] user_weights;

    // map from voter address to vote index
    mapping(address => uint) votes_index;
    
    // all votes
    // index 0 store no vote
    Vote[] votes;
    
    VoteResult result;

    struct UserWeight {
        address addr;
        uint64 weight;
    }
    
    struct Vote {
        address voter;
        
        // selected option indexes. If isAnonymous is true, ignore this field.
        uint64[] optionIDs;
        
        // vote time
        uint64 add_time;
    }
    
    struct VoteResult {
        // option indexes which has max votes count
        // if no winner, winners.length is zero.
        uint64[] winners;
        
        // votes count for each option
        uint64[] options;
        
        // total votes count
        uint64 votes;
        
        // if isPublic is true, voters_count is equal to votes_count.
        // is isPublic is false, voters_count is user_repo count.
        uint64 voters;
        
        uint64 start_time;
        
        uint64 end_time;
        
        VotingStatus status;
    }
    
    enum VotingStatus {TO_START, VOTING, ENDED, SETTLED}
    
    // params index
    uint8 P_OPTION_COUNT = 0;
    uint8 P_SELECT_MIN = 1;
    uint8 P_SELECT_MAX = 2;
    uint8 P_ISANONYMOUS = 3;
    uint8 P_ISPUBLIC = 4;
    uint8 P_MULTIWINNER = 5;
    uint8 P_THRESHOLDWINNERVOTES = 6;
    uint8 P_THRESHOLDTOTALVOTES = 7;

    // time index
    uint8 T_TO_START_TIME = 0;
    uint8 T_TO_END_TIME = 1;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function.");
        _;
    }
    
    // _params: option_count, select_min, select_max, isAnonymous, isPublic, multiWinner, thresholdWinnerVotes, thresholdTotalVotes
    // _time: to_start_time, to_end_time
    constructor(address _owner, bytes32 _content_hash, bytes _content, uint64[8] _params, uint64[2] _time, address _user_repo) public {
        require(_content_hash > 0, "content hash is not valid.");
        require(_content.length == 0 || keccak256(_content) == _content_hash, "keccak256 hash of content does not match.");
        require(_params[P_OPTION_COUNT] >= 2, "option count must be at least 2.");
        require(_params[P_SELECT_MIN] >= 1 && _params[P_SELECT_MAX] <= _params[P_OPTION_COUNT], "select option count must be between 1 and option count.");
        require(_time[T_TO_START_TIME] == 0 || _time[T_TO_START_TIME] >= now, "to start time must be 0 or greater then now.");
        require(_time[T_TO_END_TIME] == 0 || _time[T_TO_END_TIME] >= now, "to end time must be 0 or greater then now.");
        // percent
        require(_params[P_ISPUBLIC] > 0 || _params[P_THRESHOLDTOTALVOTES] <= 100, "threshold of total votes is not a percent.");
        require(_params[P_THRESHOLDWINNERVOTES] <= 100, "threshold of winner votes is not a percent.");
        require(_params[P_ISPUBLIC] > 0 || _user_repo > 0, "user repository required for non public voting.");

        if (_owner == 0) {
            owner = msg.sender;
        } else {
            owner = _owner;
        }
        
        content_hash = _content_hash;
        content = _content;
        
        option_count = _params[P_OPTION_COUNT];
        select_min = _params[P_SELECT_MIN];
        select_max = _params[P_SELECT_MAX];
        isAnonymous = _params[P_ISANONYMOUS];
        isPublic = _params[P_ISPUBLIC];
        multiWinner = _params[P_MULTIWINNER];
        thresholdWinnerVotes = uint8(_params[P_THRESHOLDWINNERVOTES]);
        thresholdTotalVotes = _params[P_THRESHOLDTOTALVOTES];

        result.options = new uint64[](option_count);

        to_start_time = _time[T_TO_START_TIME];
        to_end_time = _time[T_TO_END_TIME];
        create_time = uint64(now);
        
        if (isPublic == 0) {
            user_repo = UserRepository(_user_repo);
        }
        
        votes.push(Vote(0, new uint64[](0), 0));
        user_weights.push(UserWeight({addr:0, weight:1}));
    }

    function getContent() public view returns(bytes) {
        return content;
    }

    function setUsersWeight(address[] _users, uint64[] _weights) public returns(bool) {
        require(msg.sender == owner, "only owner can call this function.");
        require(!isStarted(), "changing user weight is forbiden after voting started.");
        require(isPublic == 0, "public voting can not set user weight.");
        require(user_repo.hasUsers(_users), "some user is not added to user repository.");

        for (uint i = 0; i < _users.length; i++) {
            if (user_weight_index[_users[i]] > 0) {
                user_weights[user_weight_index[_users[i]]].weight = _weights[i] > 1 ? _weights[i] : 1;
            } else {
                user_weight_index[_users[i]] = user_weights.length;
                user_weights.push(UserWeight(_users[i], _weights[i]));
            }
        }

        return true;
    }

    function getUsersWeight() public view returns(address[] _users, uint64[] _weights) {
        uint len = user_weights.length;

        _users = new address[](len - 1);
        _weights = new uint64[](len - 1);

        for (uint i = 1; i < len; i++) {
            _users[i - 1] = user_weights[i].addr;
            _weights[i - 1] = user_weights[i].weight;
        }
    }

    function getVotingInfo()
        public
        view 
        returns(address _owner, bytes32 _content_hash, uint64[8] _params, uint64[3] _time, address _user_repo)
    {
        _owner = owner;
        _content_hash = content_hash;
        _params = [option_count, select_min, select_max, isAnonymous, isPublic, multiWinner, thresholdWinnerVotes, thresholdTotalVotes];
        _time = [to_start_time, to_end_time, create_time];
        _user_repo = user_repo;
    }

    // _extra: _votes, _voters, _start_time, _end_time, _status
    function getVotingResult()
        public
        view 
        returns(uint64[] _winners, uint64[] _options, uint64[5] _extra)
    {
        VoteResult memory r = result;
        
        _winners = r.winners;
        _options = r.options;
        
        _extra[0] = r.votes;
        
        if (r.status == VotingStatus.SETTLED) {
            _extra[1] = r.voters;
        } else if (isEnded()) {
            _extra[1] = user_repo.countBefore(r.end_time > 0 ? r.end_time : to_end_time);
        } else {
            _extra[1] = user_repo.count();
        }
        
        // start_time
        _extra[2] = 0;
        // end_time
        _extra[3] = 0;
        // status
        _extra[4] = uint8(VotingStatus.TO_START);

        if (r.start_time > 0) {
            _extra[2] = r.start_time;
            _extra[4] = uint8(VotingStatus.VOTING);
        } else if (to_start_time > 0 && now >= to_start_time) {
            _extra[2] = to_start_time;
            _extra[4] = uint8(VotingStatus.VOTING);
        }
        
        if (r.end_time > 0) {
            _extra[3] = r.end_time;
            _extra[4] = uint8(VotingStatus.ENDED);
        } else if (to_end_time > 0 && now >= to_end_time) {
            _extra[3] = to_end_time;
            _extra[4] = uint8(VotingStatus.ENDED);
        }
        
        if (r.status == VotingStatus.SETTLED) {
            _extra[4] = uint8(VotingStatus.SETTLED);
        }
    }
    
    function vote(uint64[] _optionIDs) external returns(bool) {
        address voter = msg.sender;
        address voter_registered;
        uint64 add_time;        

        (voter_registered, add_time) = user_repo.getUser(msg.sender);

        require(!isEnded(), "voting has ended.");
        require(isStarted(), "voting has not started.");
        require(isPublic > 0 || (add_time > 0 && add_time <= getStartTime()), "you are not permitted to vote.");
        require(0 == votes_index[voter], "you have voted.");
        require(_optionIDs.length >= select_min && _optionIDs.length <= select_max, "vote count error.");

        bool[] memory _options = new bool[](option_count);
        
        uint64 i = 0;
        uint64 n = 0;
        
        for (i = 0; i < _optionIDs.length; i++) {
            require(_optionIDs[i] < option_count, "vote option index error");
            
            if (!_options[_optionIDs[i]]) {
                n++;
                _options[_optionIDs[i]] = true;
            }
        }
        
        Vote memory v = Vote({voter:voter, optionIDs:new uint64[](isAnonymous > 0 ? 0 : n), add_time:uint64(now)});
        uint64 weight = user_weights[user_weight_index[voter]].weight;
        
        uint j = 0;
        for (i = 0; i < option_count; i++) {
            if (_options[i]) {
                result.options[i] += weight;
                if (isAnonymous == 0) {
                    v.optionIDs[j] = i;
                    j++;
                }
            }
        }
        
        votes.push(v);
        
        result.votes = uint64(votes.length) - 1;
        
        return true;
    }
    
    function startVoting() public onlyOwner returns(bool) {
        require(to_start_time == 0, "voting is set to start automatically.");
        
        if (result.start_time == 0) {
            result.start_time = uint64(now);
            result.status = VotingStatus.VOTING;
        }
        
        return true;
    }
    
    function endVoting() public onlyOwner returns(bool) {
        require(to_end_time == 0, "voting is set to end automatically.");
        require(isStarted(), "voting has not started.");
        
        if (result.end_time == 0) {
            result.end_time = uint64(now);
            result.status = VotingStatus.ENDED;
        }
        
        return true;
    }

    function settleVoting() external returns(bool) {
        require(isEnded(), "voting has not ended.");
        
        result.votes = uint64(votes.length) - 1;
        result.voters = user_repo.countBefore(result.end_time > 0 ? result.end_time : to_end_time);
        
        uint64 max_votes_count = 0;
        uint64 winner_count = 0;
        
        uint len = 0;
        uint64 count = 0;
        uint64 i = 0;
        
        len = result.options.length;
        for (i = 0; i < len; i++) {
            count = result.options[i];
            if (max_votes_count < count) {
                max_votes_count = count;
                winner_count = 1;
            } else if (max_votes_count == count) {
                winner_count++;
            }
        }

        uint64 weightedVotes = 0;
        if (isPublic == 0) {
            len = user_weights.length;
            for (i = 1; i < len; i++) {
                weightedVotes += user_weights[i].weight - 1;
            }
        }
        
        if ((winner_count == 1 || (winner_count > 1 && multiWinner > 0))
            && (isPublic == 0 || result.votes >= thresholdTotalVotes)
            && (isPublic > 0 || result.votes * 100 >= result.voters * thresholdTotalVotes + weightedVotes)
            && max_votes_count * 100 >= result.votes * thresholdWinnerVotes
        ) {
            len = result.options.length;
            for (i = 0; i < len; i++) {
                if (max_votes_count == result.options[i]) {
                    result.winners.push(i);
                }
            }
        }
        
        result.status = VotingStatus.SETTLED;
        
        return true;
    }
    
    function isStarted() internal view returns(bool) {
        return (result.start_time > 0 || (to_start_time > 0 && now >= to_start_time));
    }
    
    function isEnded() internal view returns(bool) {
        return (result.end_time > 0 || (to_end_time > 0 && now >= to_end_time));
    }

    function getStartTime() internal view returns(uint64) {
        if (result.start_time > 0) {
            return result.start_time;
        } else if (to_start_time > 0) {
            return to_start_time;
        } else {
            return 0;
        }
    }
}
