<template>
  <div class="app-container">
    <div class="head-btn-groups" style="margin-bottom:15px;">
      <el-radio-group v-model="tab" fill="#909399">
        <el-radio-button label="IPublished">我发布的投票</el-radio-button>
        <el-radio-button label="IVoted">我参与的投票</el-radio-button>
      </el-radio-group>
      <el-button type="primary" style="float:right;" @click="$router.push('/votings/new')">发布投票</el-button>
    </div>
    <voting-list :category="tab"/>
  </div>
</template>

<script>
import VotingList from '@/views/votings/components/VotingList.vue'

export default {
  components: {
    VotingList
  },
  data() {
    return {
      tab: 'IPublished'
    }
  }
}
</script>
