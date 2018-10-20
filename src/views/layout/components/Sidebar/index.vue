<template>
  <div id="sidebar">
    <div class="logo-container">
      <a @click="pageReload()"><img class="logo" src="/static/logo.png"></a>
    </div>
    <el-scrollbar wrap-class="scrollbar-wrapper" style="height:100%;">
      <el-menu
        :show-timeout="200"
        :default-active="$route.path"
        :collapse="isCollapse"
        mode="vertical"
        background-color="#eef1f6"
        text-color="#48576a"
        active-text-color="#20a0ff"
      >
        <sidebar-item v-for="route in routes" :key="route.name" :item="route" :base-path="route.path"/>
      </el-menu>
    </el-scrollbar>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import SidebarItem from './SidebarItem'

export default {
  components: { SidebarItem },
  computed: {
    ...mapGetters([
      'sidebar'
    ]),
    routes() {
      return this.$router.options.routes
    },
    isCollapse() {
      return !this.sidebar.opened
    }
  },
  methods: {
    pageReload() {
      window.location.reload()
    }
  }
}
</script>

<style lang="scss">
.logo-container {
	text-align: center;
  width: 100%;
  background-color: #ffffff;

  .logo {
    width: 180px;
    padding: 10px 15px;
	}
}

.el-menu {
  font-weight: bold;
}
</style>
