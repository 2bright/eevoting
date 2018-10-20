import Cookies from 'js-cookie'

function emptyVoting() {
  return {
    title: '',
    description: '',
    options: [
      { title: '同意', key: 1 },
      { title: '反对', key: 2 }
    ],
    usergroup_id: null,
    select_max: 2,
    start_time: new Date(),
    end_time: new Date(Date.now() + 24 * 60 * 60 * 1000),
    n_min_total_votes: 0,
    d_min_total_votes: 1,
    n_min_winner_votes: 0,
    d_min_winner_votes: 1,
    allow_multi_winner: true
  }
}

function emptyUsergroup() {
  return {
    name: '',
    description: '',
    members: [
      { addr: '', key: 1 }
    ]
  }
}

const state = {
  editingVoting: emptyVoting(),
  editingUsergroup: emptyUsergroup()
}

const mutations = {
  onRefreshPage(state) {
    var editingVoting = Cookies.get('editingVoting')
    if (editingVoting && editingVoting.length > 0 && editingVoting !== 'undefined') {
      state.editingVoting = JSON.parse(editingVoting)
    }

    var editingUsergroup = Cookies.get('editingUsergroup')
    if (editingUsergroup && editingUsergroup.length > 0 && editingUsergroup !== 'undefined') {
      state.editingUsergroup = JSON.parse(editingUsergroup)
    }
  }
}

const actions = {
  stashEditingVoting({ commit }, editingVoting) {
    if (editingVoting && editingVoting !== 'undefined') {
      Cookies.set('editingVoting', JSON.stringify(editingVoting))
    }
  },
  stashEditingUsergroup({ commit }, editingUsergroup) {
    if (editingUsergroup && editingUsergroup !== 'undefined') {
      Cookies.set('editingUsergroup', JSON.stringify(editingUsergroup))
    }
  }
}

export default {
  state,
  actions,
  mutations
}
