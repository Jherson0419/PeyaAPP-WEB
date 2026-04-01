-- Ejecutar en Supabase → SQL Editor si la app móvil lee con la anon key.
-- La tabla debe existir (tras `prisma db push` o migración).

ALTER TABLE public."VendorBranch" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendorbranch_public_read_active" ON public."VendorBranch";
CREATE POLICY "vendorbranch_public_read_active"
  ON public."VendorBranch"
  FOR SELECT
  TO anon, authenticated
  USING ("isActive" = true);

-- El panel web (Prisma con DATABASE_URL directo) no usa esta política para INSERT;
-- si en el futuro insertas desde Supabase con usuario autenticado, añade políticas INSERT.
