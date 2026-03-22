<template>
  <section id="shortcuts" class="py-24 px-6 bg-gray-50/50">
    <div class="max-w-3xl mx-auto">
      <div class="text-center mb-12">
        <h2 class="text-3xl md:text-4xl font-bold tracking-tight mb-4">{{ t('shortcuts.title') }}</h2>
        <p class="text-gray-500 text-lg">{{ t('shortcuts.subtitle') }}</p>
      </div>

      <div class="mb-10">
        <h3 class="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4 text-center">{{ t('shortcuts.tools') }}</h3>
        <div class="flex flex-wrap justify-center gap-2">
          <ShortcutBadge v-for="s in editorShortcuts" :key="s.key" :label="s.label" :shortcut="s.key" />
        </div>
      </div>

      <div>
        <h3 class="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4 text-center">{{ t('shortcuts.actions') }}</h3>
        <div class="flex flex-wrap justify-center gap-2">
          <ShortcutBadge v-for="s in actionShortcuts" :key="s.key" :label="s.label" :shortcut="s.key" />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
const { t } = useI18n()

const editorShortcuts = [
  { key: 'V', label: 'Select' },
  { key: 'C', label: 'Crop' },
  { key: 'R', label: 'Rectangle' },
  { key: 'O', label: 'Ellipse' },
  { key: 'L', label: 'Line' },
  { key: 'A', label: 'Arrow' },
  { key: 'T', label: 'Text' },
  { key: 'D', label: 'Draw' },
  { key: 'B', label: 'Blur' },
  { key: 'N', label: 'Number' },
  { key: 'F', label: 'Background' },
]

const actionShortcuts = [
  { key: '⌘Z', label: 'Undo' },
  { key: '⌘⇧Z', label: 'Redo' },
  { key: '⌘S', label: 'Save as' },
  { key: '⌘C', label: 'Copy' },
  { key: '⌘V', label: 'Paste' },
  { key: '⌘+', label: 'Zoom in' },
  { key: '⌘-', label: 'Zoom out' },
  { key: '⌘0', label: 'Reset' },
]
</script>
