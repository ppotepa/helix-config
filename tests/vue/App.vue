<template>
  <main class="container">
    <h1>{{ title }}</h1>
    <ul>
      <li v-for="user in filtered" :key="user.id">
        {{ user.name }} ({{ user.score }})
      </li>
    </ul>
  </main>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'

type User = { id: number; name: string; score: number }

const title = ref('Hello from Vue')
const users = ref<User[]>([
  { id: 1, name: 'Ada', score: 95 },
  { id: 2, name: 'Grace', score: 91 },
  { id: 3, name: 'Linus', score: 87 },
])

const filtered = computed(() => users.value.filter(u => u.score >= 90))
</script>

<style scoped>
.container {
  max-width: 42rem;
  margin: 2rem auto;
  font-family: ui-sans-serif, system-ui;
}
</style>
