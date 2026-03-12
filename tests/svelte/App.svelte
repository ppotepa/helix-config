<script lang="ts">
  type User = { id: number; name: string; score: number }

  const title = 'Hello from Svelte'
  const users: User[] = [
    { id: 1, name: 'Ada', score: 95 },
    { id: 2, name: 'Grace', score: 91 },
    { id: 3, name: 'Linus', score: 87 }
  ]

  $: filtered = users.filter((u) => u.score >= 90)
</script>

<main class="container">
  <h1>{title}</h1>
  <ul>
    {#each filtered as user (user.id)}
      <li>{user.name} ({user.score})</li>
    {/each}
  </ul>
</main>

<style>
  .container {
    max-width: 42rem;
    margin: 2rem auto;
    font-family: ui-sans-serif, system-ui;
  }
</style>
