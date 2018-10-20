<template>
  <div v-loading="loading" class="app-container">
    <div class="view-form">
      <div class="vf-item">
        <label class="vfi-name">
          群名称：
        </label>
        <span class="vfi-value">
          {{ usergroup.name }}
        </span>
      </div>
      <div class="vf-item">
        <label class="vfi-name">
          群描述：
        </label>
        <span class="vfi-value">
          <pre class="paragraph" style="margin:0;text-indent:0;">{{ usergroup.description }}</pre>
        </span>
      </div>
      <div class="vf-item">
        <label class="vfi-name">
          创建时间：
        </label>
        <span class="vfi-value">
          {{ usergroup.create_time | formatTime }}
        </span>
      </div>
      <div class="vf-item">
        <label class="vfi-name">
          群主：
        </label>
        <span class="vfi-value">
          <el-tag>{{ usergroup.owner }}</el-tag>
        </span>
      </div>
      <div class="vf-item">
        <label class="vfi-name">
          群成员：
        </label>
        <span class="vfi-value">
          <div>{{ usergroup.members_num }} 个</div>
          <!--el-button size="mini" type="primary" style="margin-left:20px">添加成员</el-button-->
        </span>
      </div>
      <div v-if="usergroup.members && usergroup.members.length > 0" class="vf-item">
        <label class="vfi-name"/>
        <span class="vfi-value">
          <el-tag v-for="member in usergroup.members" :key="member.addr" style="margin: 0 10px 10px 0">{{ member.addr }}</el-tag>
        </span>
      </div>
    </div>
  </div>
</template>

<script>
import ethApi from '@/api/eth'

export default {
  data() {
    return {
      loading: true,
      usergroup: {}
    }
  },
  created() {
    this.getUsergroup()
  },
  methods: {
    getUsergroup() {
      this.loading = true

      ethApi.getUsergroup(this.$route.params.id)
        .then(rsp => {
          this.usergroup = rsp
          this.loading = false
        })
        .catch(() => {
          this.loading = false
        })
    }
  }
}
</script>
