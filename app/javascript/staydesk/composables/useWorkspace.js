import { computed } from 'vue';
import { useWorkspaceStore } from '../store/workspace';

// A área de trabalho resolvida para o usuário, lida pelos ganchos do upstream.
// Lista ausente (null) significa "sem restrição".
export const useWorkspace = () => {
  const store = useWorkspaceStore();

  const config = computed(() => store.config);
  const role = computed(() => store.config.role);
  const isTable = computed(() => store.config.list?.layout === 'table');
  // Com o atendimento aberto, a lista some e sobra dados, conversa e aplicativos.
  const hidesListWhenOpen = computed(
    () => store.config.list?.hide_when_open === true
  );
  const columns = computed(() => store.config.list?.columns || []);
  const fields = computed(() => store.config.conversation?.fields);
  const composer = computed(() => store.config.composer || {});

  const allowedBy = list => value =>
    !Array.isArray(list) || list.includes(value);

  const filterMenuNames = names => names.filter(allowedBy(store.config.menu));

  // Abas da lista de conversas: quem não vê fila fica só com as suas.
  const filterAssigneeTabs = tabs =>
    tabs.filter(tab => allowedBy(store.config.list?.tabs)(tab.key));

  // Aplicativos que a área de trabalho manda mostrar ao lado da conversa entram
  // como seções do painel direito, com um nome próprio que o gancho reconhece.
  const APP_PANEL_PREFIX = 'staydesk_app_';
  const sideAppPanels = () =>
    (store.config.conversation?.side_apps || []).map(id => ({
      name: `${APP_PANEL_PREFIX}${id}`,
    }));

  const filterPanels = order => {
    const panels = store.config.conversation?.panels;
    const apps = sideAppPanels();
    if (!Array.isArray(panels)) return [...order, ...apps];
    const byName = new Map(order.map(item => [item.name, item]));
    return [
      ...panels.filter(name => byName.has(name)).map(name => byName.get(name)),
      ...apps,
    ];
  };

  const appIdFromPanel = name =>
    String(name || '').startsWith(APP_PANEL_PREFIX)
      ? name.slice(APP_PANEL_PREFIX.length)
      : null;

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
    hidesListWhenOpen,
    columns,
    fields,
    composer,
    filterMenuNames,
    filterAssigneeTabs,
    filterPanels,
    appIdFromPanel,
    filterApps,
    allowsMacro,
    ensureLoaded,
  };
};
