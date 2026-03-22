<template>
  <section id="features" class="py-24 px-6">
    <div class="max-w-5xl mx-auto">
      <div class="text-center mb-14">
        <h2 class="text-3xl md:text-4xl font-bold tracking-tight mb-4">{{ t('features.title') }}</h2>
        <p class="text-gray-500 text-lg">{{ t('features.subtitle') }}</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <FeatureCard
          v-for="feature in features"
          :key="feature.key"
          :icon="feature.icon"
          :title="t(`feature.${feature.key}.title`)"
          :description="t(`feature.${feature.key}.desc`)"
        />
      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()

const features = [
  { key: 'capture', icon: 'mdi:camera-burst' },
  { key: 'ocr', icon: 'mdi:text-recognition' },
  { key: 'preview', icon: 'mdi:picture-in-picture-bottom-right' },
  { key: 'editor', icon: 'mdi:pencil-ruler' },
  { key: 'background', icon: 'mdi:gradient-horizontal' },
  { key: 'history', icon: 'mdi:history' },
  { key: 'update', icon: 'mdi:update' },
  { key: 'bilingual', icon: 'mdi:translate' },
]
</script>
