export type VendorBranchRow = {
  id: string;
  name: string;
  address: string;
  verticalId?: string | null;
  categoryId?: string;
  categoryName?: string;
  iconUrl: string | null;
  latitude: number;
  longitude: number;
};

export type BranchCategoryOption = {
  id: string;
  name: string;
};
