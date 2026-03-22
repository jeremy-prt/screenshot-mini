<template>
  <div class="flex items-center gap-2 px-3 py-2 rounded-xl bg-white border border-gray-200/80 shadow-sm">
    <kbd class="px-2 py-0.5 bg-gray-100 rounded-md text-xs font-mono font-bold text-gray-700 min-w-[24px] text-center">
      {{ shortcut }}
    </kbd>
    <span class="text-xs text-gray-500">{{ label }}</span>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  shortcut: string
  label: string
}>()
</script>
