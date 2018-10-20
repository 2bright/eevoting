import Vue from 'vue'
import Tool from './tool'

Vue.filter('formatTime', (time) => Tool.formatTime(time))
Vue.filter('votingStatusText', (status_id) => Tool.votingStatusText(status_id))

Vue.prototype.$filters = Vue.options.filters
