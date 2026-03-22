<template>
  <footer class="py-10 px-6 border-t border-gray-100">
    <div class="max-w-5xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
      <div class="flex items-center gap-2">
        <img src="/logo.svg" alt="Orby" class="w-5 h-5" />
        <span class="text-sm font-semibold text-gray-400">Orby</span>
      </div>

      <div class="flex items-center gap-5 text-xs text-gray-400">
        <a href="https://github.com/jeremy-prt/orby" target="_blank" class="hover:text-brand transition-colors">GitHub</a>
        <a href="https://github.com/jeremy-prt/orby/releases" target="_blank" class="hover:text-brand transition-colors">Releases</a>
        <a href="https://github.com/jeremy-prt/orby/blob/main/LICENSE" target="_blank" class="hover:text-brand transition-colors">MIT License</a>

        <!-- Lang selector -->
        <div class="relative flex items-center gap-1.5">
          <Icon name="mdi:web" class="text-sm" />
          <select
            :value="lang"
            @change="setLang($event.target.value)"
            class="appearance-none bg-gray-100 text-[10px] font-semibold rounded-full pl-2.5 pr-6 py-1 text-gray-600 cursor-pointer hover:bg-gray-200 transition-colors focus:outline-none"
          >
            <option v-for="l in langs" :key="l.code" :value="l.code">{{ l.label }}</option>
          </select>
          <Icon name="mdi:chevron-down" class="absolute right-1.5 top-1/2 -translate-y-1/2 text-[10px] text-gray-400 pointer-events-none" />
        </div>
      </div>

      <p class="text-xs text-gray-400">
        {{ t('footer.made') }} <a href="https://github.com/jeremy-prt" target="_blank" class="hover:text-brand transition-colors">Jeremy Perret</a>
      </p>
    </div>
  </footer>
</template>

<script setup>
const { t, lang, langs, setLang } = useI18n()
</script>
