<template>
  <div class="app-container">
    <el-form ref="editingUsergroup" :model="editingUsergroup" :rules="rules" label-width="150px">
      <el-form-item label="群名称" prop="name">
        <el-input v-model="editingUsergroup.name"/>
      </el-form-item>
      <el-form-item label="群描述" prop="description">
        <el-input :rows="3" v-model="editingUsergroup.description" type="textarea"/>
      </el-form-item>
      <el-form-item
        v-for="(member, index) in editingUsergroup.members"
        :label="'成员' + (index + 1) + ':ETH地址'"
        :key="'addr' + member.key"
        :prop="'members.' + index + '.addr'"
        :rules="[
          { required: true, message: '请输入成员的ETH地址', trigger: 'blur' },
          { min: 42, max: 42, message: 'ETH地址错误', trigger: 'blur' }
        ]"
      >
        <el-input v-model="member.addr" style="width:500px;"/>
        <el-button @click.prevent="removeMember(member)">删除</el-button>
      </el-form-item>
      <el-form-item>
        <el-button @click="addMember">添加成员</el-button>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" @click="showSubmitDialog()">创建</el-button>
      </el-form-item>
    </el-form>
    <el-dialog
      :visible.sync="dialogVisible"
      width="30%">
      <template v-if="validationPass">
        <div>创建后不可更改！</div>
        <div>创建后不可添加成员！</div>
        <br>
        <div>是否确定创建？</div>
      </template>
      <template v-else>
        <div>{{ dialogMessage }}</div>
      </template>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button v-if="validationPass" type="primary" @click="createUsergroup()">创建</el-button>
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
      existingNames: [],
      rules: {
        name: [
          { required: true, message: '请输入群名称', trigger: 'blur' },
          { min: 1, max: 32, message: '不超过 32 个字符，不超过10个汉字', trigger: 'blur' },
          { validator: this.checkUsergroupNameLength, trigger: 'blur' },
          { validator: this.checkUsergroupNameExistance, trigger: 'blur' }
        ],
        description: [
          { max: 3072, message: '不超过3000个字符, 不超过1000个汉字', trigger: 'blur' },
          { validator: this.checkDescriptionLength, trigger: 'blur' }
        ]
      }
    }
  },
  computed: {
    editingUsergroup() {
      var v = this.$store.state.stash.editingUsergroup
      this.$store.dispatch('stashEditingUsergroup', v)
      return v
    }
  },
  methods: {
    removeMember(member) {
      var index = this.editingUsergroup.members.indexOf(member)
      if (index !== -1) {
        this.editingUsergroup.members.splice(index, 1)
      }
    },
    addMember() {
      this.editingUsergroup.members.push({
        addr: '',
        key: Date.now()
      })
    },
    checkUsergroupNameExistance(rule, value, callback) {
      if (!value) {
        return callback()
      }

      if (this.existingNames[value]) {
        return callback(new Error('群名称已存在'))
      }

      // 使用查询接口检查是否重名，避免创建时失败浪费手续费，并且不需要等待
      ethApi.hasUsergroupName(value)
        .then((has) => {
          if (has) {
            this.existingNames[value] = true
            callback(new Error('群名称已存在'))
          } else {
            callback()
          }
        }).catch(() => {
          callback('出现错误，无法检查群名称')
        })
    },
    checkUsergroupNameLength(rule, value, callback) {
      var nameAsHex = ethApi.web3.utils.stringToHex(this.editingUsergroup.name)
      if (nameAsHex.length > 32 * 2 + 2) {
        return callback(new Error('群名称长度超过32字节！注意一个汉字占3个字节！'))
      } else {
        return callback()
      }
    },
    checkDescriptionLength(rule, value, callback) {
      var hexString = ethApi.web3.utils.stringToHex(this.editingUsergroup.description)
      if (hexString.length > 3072 * 2 + 2) {
        return callback(new Error('长度不能超过3000字节！注意一个汉字占3个字节！'))
      } else {
        return callback()
      }
    },
    showSubmitDialog() {
      this.$refs['editingUsergroup'].validate((valid) => {
        this.dialogMessage = valid ? '' : '数据验证失败，请检查！'
        this.validationPass = valid
        this.dialogVisible = true
      })
    },
    createUsergroup() {
      this.$refs['editingUsergroup'].validate((valid) => {
        this.dialogVisible = false

        var usergroupName = this.editingUsergroup.name

        if (valid) {
          this.$message({
            message: '正在创建群 ' + usergroupName + '，请等待 20 秒 ...',
            duration: 0,
            showClose: true
          })

          ethApi.createUsergroup(this.editingUsergroup)
            .then(() => {
              this.$message.closeAll()
              this.$message.success({
                message: '群 ' + usergroupName + ' 创建成功',
                duration: 0,
                showClose: true
              })
              if (this.$router.currentRoute.path === '/usergroups/new') {
                this.$router.push('/usergroups')
              } else if (this.$router.currentRoute.path === '/usergroups') {
                window.location.reload()
              }
            })
            .catch((err) => {
              this.$message.closeAll()
              this.$message.error({
                message: '群 ' + usergroupName + ' 创建失败！\n' + err.message,
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
