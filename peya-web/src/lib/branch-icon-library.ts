export type BranchIconOption = {
  id: string;
  name: string;
  iconUrl: string;
};

export const BRANCH_ICON_LIBRARY: BranchIconOption[] = [
  { id: "restaurante", name: "Restaurante", iconUrl: "/branch-icons/restaurante.svg" },
  { id: "farmacia", name: "Farmacia", iconUrl: "/branch-icons/farmacia.svg" },
  { id: "mercado", name: "Mercado", iconUrl: "/branch-icons/mercado.svg" },
  { id: "cafeteria", name: "Cafetería", iconUrl: "/branch-icons/cafeteria.svg" },
  { id: "bodega", name: "Bodega", iconUrl: "/branch-icons/bodega.svg" },
  { id: "tienda", name: "Tienda", iconUrl: "/branch-icons/tienda.svg" }
];

