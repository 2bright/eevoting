<template>
  <div class="app-container">
    <div class="head-btn-groups" style="margin-bottom:15px;">
      <el-radio-group v-model="tab" fill="#909399">
        <el-radio-button label="usergroupsIAmIn">我所在的群</el-radio-button>
        <el-radio-button label="usergroupsICreated">我创建的群</el-radio-button>
      </el-radio-group>
      <el-button type="primary" style="float:right;" @click="$router.push('usergroups/new')">创建群</el-button>
    </div>
    <el-table
      v-loading="loading"
      :data="usergroups"
      border
      style="width: 100%"
      @cell-dblclick="(row) => $router.push('/usergroups/view/' + row.id)"
    >
      <el-table-column
        prop="name"
        label="群名称"
        min-width="200">
        <template slot-scope="scope">
          <router-link :to="'/usergroups/view/' + scope.row.id">{{ scope.row.name }}</router-link>
        </template>
      </el-table-column>
      <el-table-column
        prop="members_num"
        label="成员数量"
        width="120"
      />
    </el-table>
    <div class="table-foot">
      <el-pagination
        :current-page="page"
        :page-size="page_size"
        :total="total"
        layout="->, total, prev, pager, next"
        @current-change="pageChange"
      />
    </div>
  </div>
</template>

<script>
import ethApi from '@/api/eth'

export default {
  data() {
    return {
      loading: true,
      tab: 'usergroupsIAmIn',
      page_size: process.env.PAGE_SIZE,
      page: 1,
      total: 0,
      usergroups: []
    }
  },
  watch: {
    tab: function() {
      this.page = 1
      this.usergroups = []
      this.getUsergroups()
    }
  },
  created() {
    this.getUsergroups()
  },
  methods: {
    pageChange(currentPage) {
      this.page = currentPage
      this.getUsergroups()
    },
    getUsergroups() {
      this.loading = true

      var method = 'getU' + this.tab.substring(1)
      ethApi[method](this.page, this.page_size)
        .then(rsp => {
          this.usergroups = rsp.usergroups
          this.total = Number(rsp.total)
          this.loading = false
        })
        .catch(() => {
          this.loading = false
        })
    }
  }
}
</script>
