import { default as Web3 } from 'web3'
import votingContractArtifact from '../../dist/contracts/VotingSystem.json'
import { Message } from 'element-ui'

const ethApi = (() => {
  var toHexN = function(value, hexLen) {
    return ('0000000000000000000000000000000000000000000000000000000000000000' + Number(value).toString(16)).slice(-hexLen)
  }

  var toHex8 = function(value) {
    return toHexN(value, 8)
  }

  var mixToByte32 = function(fields) {
    var mix = ''
    for (var i = 0; i < fields.length; i++) {
      mix = toHex8(fields[i]) + mix
    }
    mix = '0x' + ('0000000000000000000000000000000000000000000000000000000000000000' + mix).slice(-64)
    return mix
  }

  var random = function() {
    return Math.floor(Math.random() * (2 ** 32 - 1))
  }

  var getUint32 = function(bytes32, field_index_r) {
    if (bytes32.substring(0, 2) !== '0x') {
      throw new Error('bytes32 must start with 0x')
    }
    var field_index = 7 - field_index_r
    return parseInt(bytes32.substring(2 + field_index * 8, 2 + (field_index + 1) * 8), 16)
  }

  var statusId = function(voting) {
    return voting.eth_time < voting.start_time ? 0 : (voting.eth_time > voting.end_time ? 2 : 1)
  }

  return {
    votingContractAddress: '0xC89Ce4735882C9F0f0FE26686c53074E09B0D550',

    web3: null,
    votingContract: null,

    _errorNoWeb3: '请先安装 Mist 或 MetaMask',
    _errorNoAccount: '请先用 Mist 或 MetaMask 登录以太坊',

    votingCategory: {
      IPublished: 0,
      IVoted: 1,
      IWatching: 2,
      InPublic: 3,
      InUsergroup: 4
    },

    request(callback) {
      if (Web3.givenProvider) {
        // Use Mist/MetaMask's provider
        this.web3 = new Web3(Web3.givenProvider)
        this.votingContract = new this.web3.eth.Contract(votingContractArtifact.abi, this.votingContractAddress, { gas: 7000000 })
      }

      return new Promise((resolve, reject) => {
        if (!this.web3) {
          reject(new Error(this._errorNoWeb3))
        } else if (this.votingContract.options.from) {
          resolve()
        } else {
          this.web3.eth.getAccounts()
            .then((accounts) => {
              if (accounts.length > 0) {
                this.votingContract.options.from = accounts[0]
                resolve()
              } else {
                reject(new Error(this._errorNoAccount))
              }
            })
            .catch((err) => {
              reject(err)
            })
        }
      }).then(() => {
        return callback()
      }).catch((err) => {
        console.error(err)

        Message.error({
          message: err.message,
          duration: 0,
          showClose: true
        })
        throw err
      })
    },

    hasUsergroupName(name) {
      return this.request(() => {
        return this.votingContract.methods.hasUsergroupName(Web3.utils.stringToHex(name)).call()
      })
    },

    getUsergroup(usergroup_id) {
      return this.request(() => {
        return this.votingContract.methods.getUsergroup(usergroup_id).call()
          .then(rsp => this.parseUsergroupResponse(rsp))
      })
    },

    parseUsergroupResponse(rsp) {
      var usergroup = {
        owner: rsp._owner,
        name: Web3.utils.hexToString(rsp._name),
        description: rsp._description,
        id: getUint32(rsp._mix, 0),
        create_time: getUint32(rsp._mix, 1),
        members_num: getUint32(rsp._mix, 2),
        members: []
      }
      for (var i = 0; i < rsp._members.length; i++) {
        usergroup.members.push({
          addr: rsp._members[i],
          add_time: rsp._members_time[i]
        })
      }
      return usergroup
    },

    getUsergroupsICreated(page, pagesize) {
      page = page || 1
      pagesize = pagesize || 20

      return this.request(() => {
        return this.votingContract.methods.getUsergroupsICreated(page, pagesize).call()
          .then(rsp => this.parseUsergroupsResponse(rsp))
      })
    },

    getUsergroupsIAmIn(page, pagesize) {
      page = page || 1
      pagesize = pagesize || 20

      return this.request(() => {
        return this.votingContract.methods.getUsergroupsIAmIn(page, pagesize).call()
          .then(rsp => this.parseUsergroupsResponse(rsp))
      })
    },

    parseUsergroupsResponse(rsp) {
      var usergroups = []
      var name
      for (var i = 0; i < rsp._mixes.length; i++) {
        try {
          name = this.web3.utils.hexToString(rsp._names[i])
        } catch (err) {
          console.error(err)
          name = this.web3.utils.hexToAscii(rsp._names[i])
        }
        usergroups.push({
          name: name,
          id: getUint32(rsp._mixes[i], 0),
          create_time: getUint32(rsp._mixes[i], 1),
          members_num: getUint32(rsp._mixes[i], 2)
        })
      }
      return {
        total: rsp._total,
        usergroups: usergroups
      }
    },

    createUsergroup(data, on) {
      return this.request(() => {
        var members = []
        for (var i = 0; i < data.members.length; i++) {
          members.push(data.members[i].addr)
        }

        on = on || (v => v)
        return on(this.votingContract.methods.createUsergroup(Web3.utils.stringToHex(data.name), data.description, members).send())
      })
    },

    getVotingNonce() {
      return this.request(() => {
        return this.votingContract.methods.getVotingNonce().call()
      })
    },

    validateVotingParams(data) {
      return this.request(() => {
        var title = Web3.utils.stringToHex(data.title)
        var param_arr = [[
          data.usergroup_id || 0,
          data.options.length,
          1,
          data.select_max,
          parseInt(new Date(data.start_time).getTime() / 1000),
          parseInt(new Date(data.end_time).getTime() / 1000)
        ], [
          data.allow_multi_winner ? 1 : 0,
          data.n_min_total_votes,
          data.d_min_total_votes,
          data.n_min_winner_votes,
          data.d_min_winner_votes
        ]]
        var params = [mixToByte32(param_arr[0]), mixToByte32(param_arr[1])]

        return this.votingContract.methods.validateVotingParams(params, title).call()
      })
    },

    publishVoting(data) {
      return this.getVotingNonce().then(nonce => {
        var title = Web3.utils.stringToHex(data.title)
        var param_arr = [[
          data.usergroup_id || 0,
          data.options.length,
          1,
          data.select_max,
          parseInt(new Date(data.start_time).getTime() / 1000),
          parseInt(new Date(data.end_time).getTime() / 1000)
        ], [
          data.allow_multi_winner ? 1 : 0,
          data.n_min_total_votes,
          data.d_min_total_votes,
          data.n_min_winner_votes,
          data.d_min_winner_votes
        ]]
        var params = [mixToByte32(param_arr[0]), mixToByte32(param_arr[1])]

        // content slice

        var i

        var content = { desc: data.description, opts: [] }
        for (i = 0; i < data.options.length; i++) {
          content.opts.push({ t: data.options[i].title })
        }
        var content_hex = Web3.utils.stringToHex(JSON.stringify(content))

        var slice_size = 4 * 1024
        var slices_num = Math.ceil((content_hex.length - 2) / 2 / slice_size)

        var client_nonce = random()
        var metas = []
        var slices = []

        for (i = 0; i < slices_num; i++) {
          metas[i] = mixToByte32([nonce, client_nonce, slices_num, i])
          slices[i] = '0x' + content_hex.substring(2 + slice_size * 2 * i, 2 + slice_size * 2 * (i + 1))
        }

        return new Promise((resolve, reject) => {
          var mined_slices_num = 0

          var onSliceMined = () => {
            mined_slices_num++
            if (mined_slices_num === slices_num) {
              resolve()
            }
          }

          var publishSlice = (slice_index) => {
            if (slice_index >= slices_num) {
              return
            }
            this.votingContract.methods.publishVotingSlice(metas[slice_index], slices[slice_index]).send()
              .on('transactionHash', () => {
                publishSlice(slice_index + 1)
              }).then(() => {
                onSliceMined()
              }).catch((err) => {
                console.error('error occurs when publish slice index ' + slice_index)
                reject(err)
              })
          }

          this.votingContract.methods.publishVoting(metas[0], slices[0], params, title).send()
            .on('transactionHash', () => {
              publishSlice(1)
            }).then(() => {
              onSliceMined()
            }).catch((err) => {
              console.error('error occurs when publish slice index 0')
              reject(err)
            })
        })
      })
    },

    getVotingMix(voting_id) {
      return this.request(() => {
        return this.votingContract.methods.getVotingMix(voting_id).call()
          .then(rsp => this.parseVotingMixResponse(rsp))
      })
    },

    parseVotingMixResponse(rsp) {
      var options = []
      var winners = []
      var my_vote = []

      for (var i = 0; i < rsp._options_mix.length; i++) {
        options.push({
          votes_num: getUint32(rsp._options_mix[i], 0),
          i_voted: getUint32(rsp._options_mix[i], 1) > 0,
          is_winner: getUint32(rsp._options_mix[i], 2) > 0
        })

        if (options[i].i_voted) {
          my_vote.push(i)
        }

        if (options[i].is_winner) {
          winners.push(i)
        }
      }

      var voting = {
        owner: Web3.utils.toChecksumAddress('0x' + rsp._mixes[0].substring(26)),
        title: Web3.utils.hexToString(rsp._title),

        options: options,
        my_vote: my_vote,
        winners: winners,

        usergroup_id: getUint32(rsp._mixes[1], 0),
        my_vote_time: getUint32(rsp._mixes[1], 1),
        select_min: getUint32(rsp._mixes[1], 2),
        select_max: getUint32(rsp._mixes[1], 3),
        start_time: getUint32(rsp._mixes[1], 4),
        end_time: getUint32(rsp._mixes[1], 5),
        create_time: getUint32(rsp._mixes[1], 6),
        id: getUint32(rsp._mixes[1], 7),

        allow_multi_winner: getUint32(rsp._mixes[2], 0) > 0,
        n_min_total_votes: getUint32(rsp._mixes[2], 1),
        d_min_total_votes: getUint32(rsp._mixes[2], 2),
        n_min_winner_votes: getUint32(rsp._mixes[2], 3),
        d_min_winner_votes: getUint32(rsp._mixes[2], 4),
        total_votes: getUint32(rsp._mixes[2], 5),
        winners_num: getUint32(rsp._mixes[2], 6),
        options_num: getUint32(rsp._mixes[2], 7),

        eth_time: getUint32(rsp._mixes[3], 0)
      }

      voting.status_id = statusId(voting)

      return voting
    },

    getVotingContent(voting_id) {
      return this.request(() => {
        return this.votingContract.methods.getVotingSlice(voting_id, 0).call()
          .then(rsp => {
            if (parseInt(rsp._slices_num) === 1) {
              return this.parseVotingContent([rsp._slice])
            } else {
              return new Promise((resolve, reject) => {
                var slices = [rsp._slice]

                for (var i = 1; i < rsp._slices_num; i++) {
                  this.votingContract.methods.getVotingSlice(voting_id, i).call()
                    .then((rsp) => {
                      slices[parseInt(rsp._slice_index)] = rsp._slice

                      var got_all = true
                      for (var j = 0; j < rsp._slices_num; j++) {
                        if (!slices[j]) {
                          got_all = false
                          break
                        }
                      }

                      if (got_all) {
                        resolve(this.parseVotingContent(slices))
                      }
                    }).catch((err) => {
                      reject(err)
                    })
                }
              })
            }
          })
      })
    },

    parseVotingContent(slices) {
      var i
      var content_hex = '0x'
      for (i = 0; i < slices.length; i++) {
        content_hex += slices[i].substring(2)
      }
      var content = JSON.parse(Web3.utils.hexToString(content_hex))

      var voting = {
        description: content.desc,
        options: content.opts
      }

      for (i = 0; i < voting.options.length; i++) {
        voting.options[i].title = voting.options[i].t
        delete voting.options[i].t
      }

      return voting
    },

    mergeVotingContent(voting, voting_content) {
      voting.description = voting_content.description

      for (var i = 0; i < voting.options.length; i++) {
        voting.options[i].title = voting_content.options[i].title
      }

      return voting
    },

    getVotings(category, page, pagesize) {
      page = page || 1
      pagesize = pagesize || 20

      return this.request(() => {
        return this.votingContract.methods.getVotings(this.votingCategory[category], page, pagesize).call()
          .then(rsp => this.parseVotingsResponse(rsp))
      })
    },

    parseVotingsResponse(rsp) {
      var votings = []

      for (var i = 0; i < rsp._voting_ids.length; i++) {
        votings.push({
          id: rsp._voting_ids[i]
        })
      }

      return {
        total: Number(rsp._total),
        votings: votings
      }
    },

    validateVote(data) {
      return this.request(() => {
        return this.votingContract.methods.validateVote(data.voting_id, data.option_ids).call()
      })
    },

    vote(data, on) {
      return this.request(() => {
        on = on || (v => v)
        return on(this.votingContract.methods.vote(data.voting_id, data.option_ids).send())
      })
    }
  }
})()

export default ethApi
