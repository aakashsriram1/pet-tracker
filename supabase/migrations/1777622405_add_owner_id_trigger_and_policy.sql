-- Auto-set owner_id on insert
CREATE OR REPLACE FUNCTION set_owner_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.owner_id := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_pets_owner_id ON pets;
CREATE TRIGGER set_pets_owner_id
BEFORE INSERT ON pets
FOR EACH ROW EXECUTE FUNCTION set_owner_id();

-- Allow authenticated users to insert their own pets
DROP POLICY IF EXISTS "users can insert own pets" ON pets;
CREATE POLICY "users can insert own pets"
ON pets FOR INSERT
WITH CHECK (auth.uid() = owner_id);
