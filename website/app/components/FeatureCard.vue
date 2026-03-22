<template>
  <div class="group p-5 rounded-2xl bg-gray-50/80 border border-gray-100 hover:border-brand/20 hover:bg-brand-subtle transition-all duration-200">
    <div class="w-10 h-10 rounded-xl bg-brand-overlay/48 flex items-center justify-center mb-3 group-hover:bg-brand-overlay/60 transition-colors">
      <Icon :name="icon" class="text-xl text-brand" />
    </div>
    <h3 class="font-semibold text-sm mb-1">{{ title }}</h3>
    <p class="text-xs text-gray-500 leading-relaxed">{{ description }}</p>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string
  title: string
  description: string
}>()
</script>
