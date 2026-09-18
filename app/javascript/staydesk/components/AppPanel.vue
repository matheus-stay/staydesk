<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import DashboardAppFrame from 'dashboard/components/widgets/DashboardApp/Frame.vue';

// Aplicativo ao lado da conversa (SPEC-17), como no Zendesk: o mesmo iframe que o
// produto já sabe alimentar, só que no painel direito e recolhível.
const props = defineProps({
  appId: { type: [Number, String], required: true },
  position: { type: Number, default: 0 },
});

const apps = useMapGetter('dashboardApps/getRecords');
const currentChat = useMapGetter('getSelectedChat');

const app = computed(() =>
  apps.value.find(item => String(item.id) === String(props.appId))
);
</script>

<template>
  <div v-if="app" class="staydesk-app-panel">
    <AccordionItem :title="app.title" is-open>
      <div class="h-96 w-full overflow-hidden rounded-lg border border-n-weak">
        <DashboardAppFrame
          :key="app.id"
          :config="app.content"
          :current-chat="currentChat"
          :position="position"
          is-visible
        />
      </div>
    </AccordionItem>
  </div>
</template>
