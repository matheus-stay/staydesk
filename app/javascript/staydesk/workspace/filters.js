import { useWorkspaceStore } from '../store/workspace';

// Filtros da área de trabalho para componentes do upstream em Options API,
// onde não dá para chamar o composable useWorkspace().
export const staydeskFilterApps = apps => {
  const allowed = useWorkspaceStore().config.conversation?.apps;
  if (!Array.isArray(allowed)) return apps;
  return apps.filter(app => allowed.includes(app.id));
};
