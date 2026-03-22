<template>
  <section id="changelog" class="py-24 px-6">
    <div class="max-w-3xl mx-auto">
      <div class="text-center mb-14">
        <h2 class="text-3xl md:text-4xl font-bold tracking-tight mb-4">{{ t('changelog.title') }}</h2>
        <p class="text-gray-500 text-lg">{{ t('changelog.subtitle') }}</p>
      </div>

      <!-- Empty state -->
      <div v-if="loaded && !releases.length" class="text-center py-10">
        <div class="w-12 h-12 rounded-full bg-brand-overlay/30 flex items-center justify-center mx-auto mb-4">
          <Icon name="mdi:rocket-launch-outline" class="text-2xl text-brand" />
        </div>
        <p class="text-gray-400 text-sm">{{ t('changelog.noReleases') }}</p>
      </div>

      <!-- Timeline -->
      <div v-else-if="releases.length" class="relative">
        <!-- Vertical line -->
        <div class="absolute left-4 top-0 bottom-0 w-px bg-gray-200" />

        <div
          v-for="(release, i) in visibleReleases"
          :key="release.id"
          class="relative pl-12 pb-10 last:pb-0"
        >
          <!-- Dot -->
          <div class="absolute left-2.5 top-1 w-3 h-3 rounded-full border-2 border-brand bg-white" />

          <!-- Card -->
          <div class="bg-white rounded-xl border border-gray-100 shadow-sm p-5 hover:shadow-md transition-shadow">
            <div class="flex items-center gap-3 mb-2 flex-wrap">
              <span class="text-sm font-bold text-brand">{{ release.tag_name }}</span>
              <span class="text-xs text-gray-400">{{ formatDate(release.published_at) }}</span>
              <span v-if="release.prerelease" class="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-amber-100 text-amber-700">Pre-release</span>
            </div>
            <h3 class="font-semibold text-sm mb-2">{{ release.name || release.tag_name }}</h3>
            <div
              v-if="release.body"
              class="text-xs text-gray-500 leading-relaxed prose-sm"
              v-html="renderMarkdown(release.body)"
            />
          </div>
        </div>
      </div>

      <!-- Show more / less -->
      <div v-if="releases.length > 5" class="text-center mt-8">
        <button
          @click="showAll = !showAll"
          class="text-sm font-medium text-brand hover:underline transition-colors"
        >
          {{ showAll ? t('changelog.showLess') : t('changelog.showMore') }}
        </button>
      </div>
    </div>
  </section>
</template>

<script setup>
const { t, lang } = useI18n()

const releases = ref([])
const showAll = ref(false)
const loaded = ref(false)

const visibleReleases = computed(() =>
  showAll.value ? releases.value : releases.value.slice(0, 5)
)

function formatDate(dateStr) {
  if (!dateStr) return ''
  const langMap = { en: 'en-US', fr: 'fr-FR', es: 'es-ES', de: 'de-DE' }
  return new Date(dateStr).toLocaleDateString(langMap[lang.value] || 'en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

function renderMarkdown(md) {
  return md
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/^### (.+)$/gm, '<h4 class="font-semibold text-gray-700 mt-3 mb-1">$1</h4>')
    .replace(/^## (.+)$/gm, '<h3 class="font-bold text-gray-800 mt-3 mb-1">$1</h3>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`(.+?)`/g, '<code class="px-1 py-0.5 bg-gray-100 rounded text-[11px]">$1</code>')
    .replace(/^[*-] (.+)$/gm, '<li class="ml-4 list-disc">$1</li>')
    .replace(/\n/g, '<br />')
}

onMounted(async () => {
  try {
    const res = await fetch('https://api.github.com/repos/jeremy-prt/orby/releases')
    if (res.ok) {
      releases.value = await res.json()
    }
  } catch {}
  loaded.value = true
})
</script>
