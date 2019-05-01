<template>
  <div style="margin:20px 40px;font-size:24px">以太坊时间：{{ current_time | formatTime }}</div>
</template>

<script>
import ethApi from '@/api/eth'

export default {
  data() {
    return {
      current_time: null
    }
  },
  created() {
    ethApi.getCurrentTime()
      .then((time) => {
        this.current_time = time
        console.log('current_time:' + this.current_time)
      })
  }
}
</script>
