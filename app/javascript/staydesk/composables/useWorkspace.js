import { computed } from 'vue';
import { useWorkspaceStore } from '../store/workspace';

// A área de trabalho resolvida para o usuário, lida pelos ganchos do upstream.
// Lista ausente (null) significa "sem restrição".
export const useWorkspace = () => {
  const store = useWorkspaceStore();

  const config = computed(() => store.config);
  const role = computed(() => store.config.role);
  const isTable = computed(() => store.config.list?.layout === 'table');
  const columns = computed(() => store.config.list?.columns || []);
  const fields = computed(() => store.config.conversation?.fields);
  const composer = computed(() => store.config.composer || {});

  const allowedBy = list => value =>
    !Array.isArray(list) || list.includes(value);

  const filterMenuNames = names => names.filter(allowedBy(store.config.menu));

  const filterPanels = order => {
    const panels = store.config.conversation?.panels;
    if (!Array.isArray(panels)) return order;
    const byName = new Map(order.map(item => [item.name, item]));
    return panels
      .filter(name => byName.has(name))
      .map(name => byName.get(name));
  };

  const filterApps = apps =>
    apps.filter(app => allowedBy(store.config.conversation?.apps)(app.id));

  const allowsMacro = id =>
    store.config.macros?.mode !== 'list' ||
    (store.config.macros.ids || []).includes(id);

  const ensureLoaded = async () => {
    if (store.uiFlags.hasFetched) return;
    await store.fetch();
  };

  return {
    config,
    role,
    isTable,
    columns,
    fields,
    composer,
    filterMenuNames,
    filterPanels,
    filterApps,
    allowsMacro,
    ensureLoaded,
  };
};
