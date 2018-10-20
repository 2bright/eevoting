<template>
  <div v-loading="loading" class="app-container">
    <div v-if="voting">
      <div class="title">{{ voting.title }}</div>
      <pre class="paragraph">{{ voting.description ? voting.description.trim() : '' }}</pre>
      <pre class="paragraph" style="font-size:12px;font-weight:bold;">本次投票由 {{ voting.owner }} 发布于 {{ voting.create_time | formatTime }}</pre>
      <div class="voting-section">
        <div class="v-settings">
          <div>
            <el-tag v-if="voting.usergroup_id === 0" type="info">公开投票</el-tag>
            <el-tag v-else type="info">来自 <router-link :to="'/usergroups/view/' + voting.usergroup_id" style="color:#409EFF;text-decoration:underline;">{{ usergroup ? usergroup.name : '' }}</router-link> 群的投票</el-tag>
            <el-tag type="info">最少总票数：{{ voting.d_min_total_votes === 1 ? (voting.n_min_total_votes + ' 票') : (voting.n_min_total_votes + ' / ' + voting.d_min_total_votes) }}</el-tag>
            <el-tag type="info">最少胜出票数：{{ voting.d_min_winner_votes === 1 ? (voting.n_min_winner_votes + ' 票') : (voting.n_min_winner_votes + ' / ' + voting.d_min_winner_votes) }}</el-tag>
            <el-tag type="info">{{ voting.allow_multi_winner ? '允许多个选项胜出' : '只允许一个选项胜出' }}</el-tag>
          </div>
          <div>
            <el-tag type="info">{{ voting.select_max > 1 ? '多选：最多选 ' + voting.select_max + ' 项' : '单选' }}</el-tag>
            <el-tag type="info">投票时间：{{ voting.start_time | formatTime }} 到 {{ voting.end_time | formatTime }}</el-tag>
          </div>
        </div>
        <div class="horizontal-line"/>
        <div style="margin: 10px 0 10px 0;display:flex;align-items:center;">
          <div style="margin-right:10px;">
            <template v-if="voting.my_vote.length > 0">
              <el-tag type="success">我已投票</el-tag>
            </template>
            <template v-else-if="voting.status_id === 2" class="v-btns">
              <el-tag type="info">我未投票</el-tag>
            </template>
            <template v-else-if="voting.status_id === 1" class="v-btns">
              <el-button type="primary" @click="showVoteDialog()">投票</el-button>
              <el-button v-if="my_vote.length > 0" @click="my_vote = []">清除</el-button>
            </template>
          </div>
          <el-tag
            :type="voting.status_id === 2 ? 'info' : (voting.status_id === 1 ? 'success' : 'primary')"
            style="margin-right:10px;"
          >{{ voting.status_id | votingStatusText }}
          </el-tag>
          <el-tag style="margin-right:10px;">{{ voting.status_id === 2 ? '共有' : '已有' }} {{ voting.total_votes }} 人投票</el-tag>
          <el-tag
            v-if="voting.status_id === 2"
            :type="voting.winners_num === 0 ? 'warning' : 'success'"
            style="margin-right:10px;"
          >
            <template v-if="voting.winners_num === 0">
              本次投票无效
            </template>
            <template v-else>
              胜出选项：<template v-for="(winner, index) in voting.winners">{{ (index > 0 ? '，' : '') + winner + ')' }}</template>
            </template>
          </el-tag>
        </div>
        <div class="horizontal-line"/>
        <div class="v-options">
          <component
            :is="'el-checkbox-group'"
            :disabled="voting.my_vote.length > 0 || voting.status_id !== 1"
            v-model="my_vote"
            style="width:100%"
          >
            <div
              v-for="(option, index) in voting.options"
              :key="index"
              :class="['v-option', option.is_winner ? 'is-winner' : '']"
            >
              <div class="v-opt-info">
                <component
                  :is="'el-checkbox'"
                  :label="index"
                  class="v-opt-check"
                >{{ (index + 1) + ') ' + option.title }}</component>
                <div class="v-opt-votes">
                  <span>{{ option.votes_num }}（{{ parseInt(100 * option.votes_num / (voting.total_votes || 1)) }}%）</span>
                </div>
              </div>
              <div class="v-opt-bar">
                <div :style="{width: (100 * option.num_votes / (voting.total_votes || 1)) + '%'}" class="v-opt-bar-progress"/>
              </div>
            </div>
          </component>
        </div>
      </div>
    </div>
    <el-dialog
      :visible.sync="dialogVisible"
      width="50%">
      <template v-if="validationPass">
        <div>你投票的选项是：</div>
        <br>
        <div
          v-for="my_vote_opt in my_vote"
          :key="my_vote_opt"
          style="word-break:break-all;"
        >{{ (my_vote_opt + 1) + ') ' + voting.options[my_vote_opt].title }}
        </div>
        <br>
        <div>投票后不可更改，是否确定投票？</div>
      </template>
      <template v-else>
        <div>{{ dialogMessage }}</div>
      </template>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button v-if="validationPass" type="primary" @click="submitVote()">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import ethApi from '@/api/eth'

export default {
  data() {
    return {
      dialogVisible: false,
      dialogMessage: '',
      validationPass: false,
      loading: true,
      my_vote: [],
      voting: null,
      usergroup: null
    }
  },
  created() {
    this.getVoting()
  },
  methods: {
    getVoting() {
      this.loading = true

      var votingMix = null
      var votingContent = null

      var mergeVotingContent = () => {
        if (votingMix && votingContent) {
          this.voting = ethApi.mergeVotingContent(votingMix, votingContent)
          this.my_vote = this.voting.my_vote.length > 0 ? this.voting.my_vote : []
          this.loading = false
        }
      }

      ethApi.getVotingMix(this.$route.params.id)
        .then(rsp => {
          votingMix = rsp

          if (rsp.usergroup_id > 0) {
            ethApi.getUsergroup(rsp.usergroup_id)
              .then(rsp => {
                this.usergroup = rsp
              })
          }

          mergeVotingContent()
        })

      ethApi.getVotingContent(this.$route.params.id)
        .then(rsp => {
          votingContent = rsp
          mergeVotingContent()
        })
    },
    validateVote(callback) {
      if (this.my_vote.length < 1) {
        callback('请选择你要投票的选项')
      } else if (this.my_vote.length > this.voting.select_max) {
        callback('最多选择 ' + this.voting.select_max + ' 个选项')
      } else {
        // 使用查询接口检查，避免创建时失败浪费手续费，并且不需要等待
        ethApi.validateVote({
          voting_id: this.voting.id,
          option_ids: this.my_vote
        }).then((err_msg) => {
          if (!err_msg) {
            callback()
          } else {
            callback('投票验证失败：' + err_msg)
          }
        }).catch((err) => {
          callback('投票验证失败：' + err.message)
        })
      }
    },
    showVoteDialog() {
      this.validateVote((err_msg) => {
        this.dialogMessage = err_msg
        this.validationPass = !err_msg
        this.my_vote.sort()
        this.dialogVisible = true
      })
    },
    submitVote() {
      this.validateVote((err_msg) => {
        this.dialogVisible = false

        if (err_msg) {
          this.$message.error(err_msg)
        } else {
          this.$message({
            message: '正在提交你的投票，请等待 20 秒 ...',
            duration: 0,
            showClose: true
          })

          var voting_id = this.voting.id

          ethApi.vote({
            voting_id: this.voting.id,
            option_ids: this.my_vote
          }).then(() => {
            this.$message.closeAll()
            this.$message.success({
              message: '你的投票提交成功',
              duration: 0,
              showClose: true
            })
            if (this.$router.currentRoute.path === '/votings/view/' + voting_id) {
              window.location.reload()
            }
          }).catch((err) => {
            this.$message.closeAll()
            this.$message.error({
              message: '你的投票提交失败！\n' + err.message,
              duration: 0,
              showClose: true
            })
          })
        }
      })
    }
  }
}
</script>

<style lang="scss">
.voting-section {
  font-size: 14px;
  border: solid 1px #ddd;
  background-color: #fafafa;
  border-radius: 5px;
  padding: 15px;

  .v-settings {
    margin-top: -10px;

    .el-tag {
      margin: 10px 10px 0 0;
    }
  }

  .horizontal-line {
    margin: 15px 0 15px 0;
    height: 1px;
    background-color: #ddd;
  }

  .v-options {
    .v-option {
      margin-top: 15px;

      &.is-winner {
        .v-opt-info {
          .v-opt-votes {
            color: #67c23a;
          }
        }
      }

      .v-opt-info {
        display: flex;
        align-items: flex-end;
        justify-content: space-between;

        .v-opt-check {
          flex: 0 1 auto;

          .el-checkbox__label {
            user-select: all;
            white-space: pre-wrap;
            word-break: break-all;
            display: inline-block;
            padding-left: 10px;
            color: #606266;
            font-weight: 500;
            font-size: 14px;
          }

          &.is-disabled {
            .el-checkbox__label {
              cursor: auto;
            }
          }

          .el-checkbox__input.is-disabled.is-checked .el-checkbox__inner {
            background-color: #409EFF;
            border-color: #409EFF;
          }

          .el-checkbox__input.is-disabled.is-checked .el-checkbox__inner::after {
            border-color: #fff;
          }
        }
        .v-opt-votes {
          flex: 0 0 auto;
          font-size: 12px;
          color: #909399;
          width: 150px;
          text-align: right;
        }
      }
      .v-opt-bar {
        height: 10px;
        width: 100%;
        margin: 5px 0 0 0;
        background-color: #ddd;
      }
      .v-opt-bar-progress {
        height: 100%;
        background-color: #bbb;
      }
    }
  }

  .v-btns {
    margin-top: 15px;
  }
}
</style>
