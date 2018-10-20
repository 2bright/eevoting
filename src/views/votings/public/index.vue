<template>
  <div class="app-container">
    <voting-list category="InPublic"/>
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
