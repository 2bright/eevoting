<template>
  <div class="navbar" mode="horizontal">
    <hamburger v-if="device === 'mobile'" :toggle-click="toggleSideBar" :is-active="sidebar.opened" class="hamburger-container"/>
    <span v-if="device !== 'mobile'" class="header-title">
      以太坊 永远铭记 你的选择 <span class="sub-header-title">这是一个把以太坊作为唯一后端服务的去中心化投票系统，以太坊将与你的数据共存亡。</span>
    </span>
    <span v-else class="header-title">
      倍易投票 <span class="sub-header-title">以太坊 永远铭记 你的选择</span>
    </span>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Hamburger from '@/components/Hamburger'

export default {
  components: {
    Hamburger
  },
  computed: {
    ...mapGetters([
      'sidebar'
    ]),
    device() {
      return this.$store.state.ui.device
    }
  },
  methods: {
    toggleSideBar() {
      this.$store.dispatch('ToggleSideBar')
    }
  }
}
</script>

<style rel="stylesheet/scss" lang="scss" scoped>
.navbar {
  height: 60px;
  line-height: 60px;
  border-radius: 0px !important;
  background-color: rgb(48, 65, 86);

  .hamburger-container {
    line-height: 68px;
    height: 60px;
    float: left;
    padding: 0 10px;
  }

  .header-title {
    color: #ffffff;
    font-size: 22px;
    margin-left: 20px;

    .sub-header-title {
      font-size: 14px;
      margin-left: 10px;
    }
  }
}
</style>

