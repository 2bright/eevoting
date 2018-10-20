import Vue from 'vue'
import Vuex from 'vuex'
import ui from './modules/ui'
import stash from './modules/stash'
import getters from './getters'

Vue.use(Vuex)

const store = new Vuex.Store({
  modules: {
    ui,
    stash
  },
  getters
})

export default store
