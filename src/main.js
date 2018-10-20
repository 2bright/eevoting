import Vue from 'vue'

import 'normalize.css/normalize.css' // A modern alternative to CSS resets

import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import locale from 'element-ui/lib/locale/lang/zh-CN'

import '@/styles/index.scss' // global css
import '@/icons' // icon
import '@/utils/filters'

import App from './App'
import router from './router'
import store from './store'

Vue.use(ElementUI, { locale })
Vue.config.productionTip = false
store.commit('onRefreshPage')

new Vue({
  el: '#app',
  router,
  store,
  render: h => h(App)
})
