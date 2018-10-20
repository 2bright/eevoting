<template>
  <div class="app-container">
    <el-form ref="editingVoting" :model="editingVoting" :rules="rules" label-width="130px">
      <el-form-item label="投票权限" prop="is_public">
        <el-switch
          v-model="editingVoting.is_public"
          inactive-color="rgb(64,158,255)"
          active-color="rgb(19,206,102)"
          inactive-text="群投票"
          active-text="公开投票"
        />
      </el-form-item>
      <el-form-item
        v-show="!editingVoting.is_public"
        :rules="{
          required: !editingVoting.is_public, message: '请选择群', trigger: 'blur'
        }"
        label="群"
        prop="usergroup_id"
      >
        <el-select v-loading="loadingUsergroups" v-model="editingVoting.usergroup_id" placeholder="请选择群" style="width:60%;" filterable>
          <el-option
            v-for="usergroup in usergroups"
            :key="usergroup.id"
            :label="usergroup.name"
            :value="usergroup.id"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="投票主题" prop="title">
        <el-input v-model="editingVoting.title"/>
      </el-form-item>
      <el-form-item label="投票描述" prop="description">
        <el-input v-model="editingVoting.description" :rows="3" type="textarea"/>
      </el-form-item>
      <template v-for="(option, index) in editingVoting.options">
        <el-form-item
          :label="'选项' + (index + 1) + ':名称'"
          :key="'title' + option.key"
          :prop="'options.' + index + '.title'"
          :rules="{
            required: true, message: '选项名称不能为空', trigger: 'blur'
          }"
        >
          <el-input v-model="option.title" style="width:60%;"/>
          <el-button @click.prevent="removeOption(option)">删除</el-button>
        </el-form-item>
      </template>
      <el-form-item prop="options">
        <el-button @click="addOption">新增选项</el-button>
      </el-form-item>
      <el-form-item label="最多选择" prop="select_max">
        <el-input v-model="editingVoting.select_max" :max="editingVoting.options.length" type="number" min="1" style="width:100px"/> 个选项
      </el-form-item>
      <el-form-item label="开始时间" prop="start_time">
        <el-date-picker
          v-model="editingVoting.start_time"
          type="datetime"
          placeholder="请选择时间"
        />
      </el-form-item>
      <el-form-item label="结束时间" prop="end_time">
        <el-date-picker
          v-model="editingVoting.end_time"
          type="datetime"
          placeholder="请选择时间"
        />
      </el-form-item>
      <el-form-item label="最少总票数">
        <el-input v-model="editingVoting.n_min_total_votes" type="number" min="0" style="width:100px"/>
        /
        <el-input v-model="editingVoting.d_min_total_votes" type="number" min="1" style="width:100px"/>
        <span class="field-comment">分母大于1则视为比例，否则视为票数。没有要求则设为 0 / 1。<br>例如群有30个成员，每人一票，最少总票数设为 2 / 3 或 20 / 1，如果投票结束后总票数少于20，则投票没有结果。</span>
      </el-form-item>
      <el-form-item label="最少胜出票数">
        <el-input v-model="editingVoting.n_min_winner_votes" type="number" min="0" style="width:100px"/>
        /
        <el-input v-model="editingVoting.d_min_winner_votes" type="number" min="1" style="width:100px"/>
        <span class="field-comment">分母大于1则视为比例，否则视为票数。没有要求则设为 0 / 1。<br>例如最少胜出票数设为 1 / 2 或 10 / 1，如果投票结束后总票数为20，胜出选项的票数少于10，则投票没有结果。</span>
      </el-form-item>
      <el-form-item label="允许多个胜出" prop="is_public">
        <el-switch
          v-model="editingVoting.allow_multi_winner"
          inactive-color="rgb(64,158,255)"
          active-color="rgb(19,206,102)"
          inactive-text="不允许"
          active-text="允许"
        />
        <span class="field-comment">如果不允许多个胜出，那么投票结束后，如果最多得票选项有多个，则投票没有结果。</span>
      </el-form-item>
      <el-form-item style="margin-top:10px;" prop="all">
        <el-button type="primary" @click="showPublishDialog()">发布</el-button>
        <span class="field-comment field-warning">注意：投票发布后不可更改；投票发布后加入群的成员没有投票权限。</span>
      </el-form-item>
    </el-form>
    <el-dialog
      :visible.sync="dialogVisible"
      width="30%">
      <template v-if="validationPass">
        <div>投票发布后不可更改！</div>
        <div>投票发布后加入群的成员没有投票权限！</div>
        <br>
        <div>是否确定发布投票？</div>
      </template>
      <template v-else>
        <div>{{ dialogMessage }}</div>
      </template>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button v-if="validationPass" type="primary" @click="publishVoting()">发布</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import ethApi from '@/api/eth'

export default {
  data() {
    return {
      loadingUsergroups: true,
      dialogVisible: false,
      dialogMessage: '',
      validationPass: false,
      usergroups: [],
      rules: {
        title: [
          { required: true, message: '请输入主题', trigger: 'blur' },
          { min: 1, max: 256, message: '不超过256个字符, 不超过85个汉字', trigger: 'blur' },
          { validator: this.checkTitleLength, trigger: 'blur' }
        ],
        description: [
          // { max: 3072, message: '不超过3000个字符, 不超过1000个汉字', trigger: 'blur' },
          // { validator: this.checkDescriptionLength, trigger: 'blur' }
        ],
        options: [
          { validator: this.checkOptionsNum, trigger: 'blur' }
        ],
        start_time: [
          { required: true, message: '请输入投票开始时间', trigger: 'blur' }
        ],
        end_time: [
          { required: true, message: '请输入投票结束时间', trigger: 'blur' }
        ],
        all: [
          { validator: this.validateVotingParams }
        ]
      }
    }
  },
  computed: {
    editingVoting() {
      var v = this.$store.state.stash.editingVoting
      this.$store.dispatch('stashEditingVoting', v)
      return v
    }
  },
  created() {
    this.getUsergroups()
  },
  methods: {
    removeOption(option) {
      var index = this.editingVoting.options.indexOf(option)
      if (index !== -1) {
        this.editingVoting.options.splice(index, 1)
      }
      this.$refs['editingVoting'].validateField('options')
    },
    addOption() {
      this.editingVoting.options.push({
        title: '',
        key: Date.now()
      })
      this.$refs['editingVoting'].validateField('options')
    },
    getUsergroups() {
      this.loadingUsergroups = true

      ethApi.getUsergroupsIAmIn(1, 1 << 30)
        .then(rsp => {
          this.usergroups = rsp.usergroups
          this.loadingUsergroups = false
        })
        .catch(() => {
          this.loadingUsergroups = false
        })
    },
    checkTitleLength(rule, value, callback) {
      var hexString = ethApi.web3.utils.stringToHex(this.editingVoting.title)
      if (hexString.length > 256 * 2 + 2) {
        return callback(new Error('投票标题的长度不能超过256字节！注意一个汉字占3个字节！'))
      } else {
        return callback()
      }
    },
    checkDescriptionLength(rule, value, callback) {
      var hexString = ethApi.web3.utils.stringToHex(this.editingVoting.description)
      if (hexString.length > 3072 * 2 + 2) {
        return callback(new Error('投票描述的长度不能超过3000字节！注意一个汉字占3个字节！'))
      } else {
        return callback()
      }
    },
    checkOptionsNum(rule, value, callback) {
      if (this.editingVoting.options.length < 2) {
        return callback(new Error('至少添加两个投票选项！'))
      } else {
        return callback()
      }
    },
    validateVotingParams(rule, value, callback) {
      // 使用查询接口检查，避免创建时失败浪费手续费，并且不需要等待
      ethApi.validateVotingParams(this.editingVoting)
        .then((err_msg) => {
          if (!err_msg) {
            callback()
          } else {
            callback('验证失败：' + err_msg)
          }
        }).catch((err) => {
          callback('验证失败：' + err.message)
        })
    },
    showPublishDialog() {
      this.$refs['editingVoting'].validate((valid) => {
        this.dialogMessage = valid ? '' : '数据验证失败，请检查！'
        this.validationPass = valid
        this.dialogVisible = true
      })
    },
    publishVoting() {
      this.$refs['editingVoting'].validate((valid) => {
        this.dialogVisible = false

        var votingTitle = this.editingVoting.title

        if (valid) {
          this.$message({
            message: '正在发布投票 ' + votingTitle + '，请等待 20 秒 ...',
            duration: 0,
            showClose: true
          })

          ethApi.publishVoting(this.editingVoting)
            .then(() => {
              this.$message.closeAll()
              this.$message.success({
                message: '投票 ' + votingTitle + ' 发布成功',
                duration: 0,
                showClose: true
              })
              if (this.$router.currentRoute.path === '/votings/new') {
                this.$router.push('/votings/mine')
              } else if (this.$router.currentRoute.path === '/votings/mine') {
                window.location.reload()
              }
            })
            .catch((err) => {
              this.$message.closeAll()
              this.$message.error({
                message: '投票 ' + votingTitle + ' 发布失败！\n' + err.message,
                duration: 0,
                showClose: true
              })
            })
        } else {
          this.$message.error('数据验证失败，请检查！')
        }
      })
    }
  }
}
</script>
