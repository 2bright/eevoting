<template>
  <div class="app-container">
    <voting-list category="InUsergroup"/>
  </div>
</template>

<script>
import VotingList from '@/views/votings/components/VotingList.vue'

export default {
  components: {
    VotingList
  }
}
</script>
