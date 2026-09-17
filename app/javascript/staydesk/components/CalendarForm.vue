<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  calendar: { type: Object, default: null },
  isSaving: { type: Boolean, default: false },
});

const emit = defineEmits(['save', 'cancel']);

// Calendário do SLA: um horário por dia da semana e a lista de feriados.
const DAYS = [1, 2, 3, 4, 5, 6, 0];

const { t } = useI18n();

const name = ref('');
const timezone = ref('America/Sao_Paulo');
const days = ref(
  DAYS.map(day => ({
    day,
    enabled: day >= 1 && day <= 5,
    open: '09:00',
    close: '18:00',
  }))
);
const holidays = ref([]);

onMounted(() => {
  if (!props.calendar) return;
  name.value = props.calendar.name;
  timezone.value = props.calendar.timezone;
  days.value = DAYS.map(day => {
    const slot = (props.calendar.weekly_hours || []).find(
      item => Number(item.day) === day
    );
    return slot
      ? { day, enabled: true, open: slot.open, close: slot.close }
      : { day, enabled: false, open: '09:00', close: '18:00' };
  });
  holidays.value = (props.calendar.holidays || []).map(holiday => ({
    ...holiday,
  }));
});

const addHoliday = () => holidays.value.push({ date: '', name: '' });
const removeHoliday = index => holidays.value.splice(index, 1);

const submit = () => {
  if (!name.value.trim()) return;
  emit('save', {
    name: name.value.trim(),
    timezone: timezone.value,
    weekly_hours: days.value
      .filter(item => item.enabled)
      .map(({ day, open, close }) => ({ day, open, close })),
    holidays: holidays.value.filter(holiday => holiday.date),
  });
};
</script>

<template>
  <form
    class="grid gap-6 rounded-xl border border-n-weak bg-n-solid-1 p-6"
    @submit.prevent="submit"
  >
    <div class="grid gap-4 md:grid-cols-2">
      <Input v-model="name" :label="t('STAYDESK.CALENDARS.FORM.NAME')" />
      <Input
        v-model="timezone"
        :label="t('STAYDESK.CALENDARS.FORM.TIMEZONE')"
      />
    </div>

    <fieldset class="grid gap-2">
      <legend class="text-sm font-medium text-n-slate-12">
        {{ t('STAYDESK.CALENDARS.FORM.WEEKLY_HOURS') }}
      </legend>
      <div
        v-for="item in days"
        :key="item.day"
        class="flex flex-wrap items-center gap-3 text-sm text-n-slate-12"
      >
        <label class="flex w-40 items-center gap-2">
          <input v-model="item.enabled" type="checkbox" />
          {{ t(`STAYDESK.CALENDARS.DAYS.${item.day}`) }}
        </label>
        <input
          v-model="item.open"
          type="time"
          :disabled="!item.enabled"
          class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-sm"
        />
        <span class="text-n-slate-11">{{
          t('STAYDESK.CALENDARS.FORM.TO')
        }}</span>
        <input
          v-model="item.close"
          type="time"
          :disabled="!item.enabled"
          class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-sm"
        />
      </div>
    </fieldset>

    <fieldset class="grid gap-2">
      <legend class="text-sm font-medium text-n-slate-12">
        {{ t('STAYDESK.CALENDARS.FORM.HOLIDAYS') }}
      </legend>
      <div
        v-for="(holiday, index) in holidays"
        :key="index"
        class="flex flex-wrap items-center gap-3"
      >
        <input
          v-model="holiday.date"
          type="date"
          class="h-8 rounded-lg border border-n-weak bg-n-alpha-1 px-2 text-sm text-n-slate-12"
        />
        <Input
          v-model="holiday.name"
          :placeholder="t('STAYDESK.CALENDARS.FORM.HOLIDAY_NAME')"
        />
        <Button
          icon="i-woot-bin"
          slate
          sm
          type="button"
          @click="removeHoliday(index)"
        />
      </div>
      <div>
        <Button sm ghost blue type="button" @click="addHoliday">
          {{ t('STAYDESK.CALENDARS.FORM.ADD_HOLIDAY') }}
        </Button>
      </div>
    </fieldset>

    <div class="flex justify-end gap-2">
      <Button sm faded slate type="button" @click="emit('cancel')">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.CANCEL') }}
      </Button>
      <Button sm solid blue type="submit" :is-loading="isSaving">
        {{ t('STAYDESK.TEAM_VIEWS.FORM.SAVE') }}
      </Button>
    </div>
  </form>
</template>
