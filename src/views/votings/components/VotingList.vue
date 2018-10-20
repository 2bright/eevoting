<template>
  <div>
    <el-table
      v-loading="loading"
      :data="votingsLoaded"
      border
      style="width: 100%"
      @cell-dblclick="(row) => $router.push('/votings/view/' + row.id)"
    >
      <el-table-column
        prop="id"
        label="编号"
        width="100"
      >
        <template slot-scope="scope">
          <router-link :to="'/votings/view/' + scope.row.id">{{ scope.row.id }}</router-link>
        </template>
      </el-table-column>
      <el-table-column
        prop="title"
        label="主题"
        min-width="300"
      >
        <template slot-scope="scope">
          <router-link :to="'/votings/view/' + scope.row.id">{{ scope.row.title }}</router-link>
        </template>
      </el-table-column>
      <el-table-column
        prop="usergroup"
        label="权限"
        min-width="60">
        <template slot-scope="scope">
          <span v-if="scope.row.usergroup_id === 0">公开投票</span>
          <router-link v-else :to="'/usergroups/view/' + scope.row.usergroup_id">群投票</router-link>
        </template>
      </el-table-column>
      <el-table-column
        align="center"
        label="状态"
        width="100">
        <template slot-scope="scope">
          <el-tag :type="scope.row.status_id === 2 ? 'info' : 'primary'">{{ scope.row.status_id | votingStatusText }}</el-tag>
        </template>
      </el-table-column>
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
  name: 'VotingList',
  props: {
    category: {
      required: true,
      type: String
    }
  },
  data() {
    return {
      loading: true,
      page_size: process.env.PAGE_SIZE,
      page: 1,
      total: 0,
      votings: []
    }
  },
  computed: {
    votingsLoaded() {
      var votings = []
      for (var i = 0; i < this.votings.length; i++) {
        if (this.votings[i].title) {
          votings.push(this.votings[i])
        }
      }
      return votings
    }
  },
  watch: {
    category: function() {
      this.page = 1
      this.votings = []
      this.getVotings()
    }
  },
  created() {
    this.getVotings()
  },
  methods: {
    pageChange(currentPage) {
      this.page = currentPage
      this.getVotings()
    },
    getVotings() {
      this.loading = true

      ethApi.getVotings(this.category, this.page, this.page_size)
        .then(rsp => {
          this.votings = rsp.votings
          this.total = Number(rsp.total)
          this.loading = false

          for (var i = 0; i < this.votings.length; i++) {
            this.getVotingMix(i)
          }
        }).catch(() => {
          this.loading = false
        })
    },
    getVotingMix(i) {
      var id = this.votings[i].id

      ethApi.getVotingMix(id)
        .then((rsp) => {
          if (this.votings[i].id === id) {
            this.$set(this.votings, i, rsp)
          }
        })
    }
  }
}
</script>
