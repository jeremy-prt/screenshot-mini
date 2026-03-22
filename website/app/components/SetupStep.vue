<template>
  <div class="p-6 rounded-2xl bg-white/50 backdrop-blur-sm border border-white/60">
    <div class="w-8 h-8 rounded-full bg-brand text-white font-bold text-sm flex items-center justify-center mb-3">
      {{ number }}
    </div>
    <h2 class="font-semibold text-lg mb-2">{{ title }}</h2>
    <slot />
  </div>
</template>

<script setup lang="ts">
defineProps<{
  number: string
  title: string
}>()
</script>
