-- Auto-set owner_id on pet inserts and lock all pet health data to the owner.
CREATE OR REPLACE FUNCTION set_owner_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.owner_id := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS set_pets_owner_id ON pets;
CREATE TRIGGER set_pets_owner_id
BEFORE INSERT ON pets
FOR EACH ROW EXECUTE FUNCTION set_owner_id();

ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE vaccinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users can view own pets" ON pets;
CREATE POLICY "users can view own pets"
ON pets FOR SELECT
USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "users can insert own pets" ON pets;
CREATE POLICY "users can insert own pets"
ON pets FOR INSERT
WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "users can update own pets" ON pets;
CREATE POLICY "users can update own pets"
ON pets FOR UPDATE
USING (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

DROP POLICY IF EXISTS "users can delete own pets" ON pets;
CREATE POLICY "users can delete own pets"
ON pets FOR DELETE
USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "users can view own weight entries" ON weight_entries;
CREATE POLICY "users can view own weight entries"
ON weight_entries FOR SELECT
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = weight_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can insert own weight entries" ON weight_entries;
CREATE POLICY "users can insert own weight entries"
ON weight_entries FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = weight_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can update own weight entries" ON weight_entries;
CREATE POLICY "users can update own weight entries"
ON weight_entries FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = weight_entries.pet_id AND p.owner_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = weight_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can delete own weight entries" ON weight_entries;
CREATE POLICY "users can delete own weight entries"
ON weight_entries FOR DELETE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = weight_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can view own symptoms" ON symptoms;
CREATE POLICY "users can view own symptoms"
ON symptoms FOR SELECT
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = symptoms.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can insert own symptoms" ON symptoms;
CREATE POLICY "users can insert own symptoms"
ON symptoms FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = symptoms.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can update own symptoms" ON symptoms;
CREATE POLICY "users can update own symptoms"
ON symptoms FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = symptoms.pet_id AND p.owner_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = symptoms.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can delete own symptoms" ON symptoms;
CREATE POLICY "users can delete own symptoms"
ON symptoms FOR DELETE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = symptoms.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can view own diet entries" ON diet_entries;
CREATE POLICY "users can view own diet entries"
ON diet_entries FOR SELECT
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = diet_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can insert own diet entries" ON diet_entries;
CREATE POLICY "users can insert own diet entries"
ON diet_entries FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = diet_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can update own diet entries" ON diet_entries;
CREATE POLICY "users can update own diet entries"
ON diet_entries FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = diet_entries.pet_id AND p.owner_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = diet_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can delete own diet entries" ON diet_entries;
CREATE POLICY "users can delete own diet entries"
ON diet_entries FOR DELETE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = diet_entries.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can view own vaccinations" ON vaccinations;
CREATE POLICY "users can view own vaccinations"
ON vaccinations FOR SELECT
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = vaccinations.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can insert own vaccinations" ON vaccinations;
CREATE POLICY "users can insert own vaccinations"
ON vaccinations FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = vaccinations.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can update own vaccinations" ON vaccinations;
CREATE POLICY "users can update own vaccinations"
ON vaccinations FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = vaccinations.pet_id AND p.owner_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = vaccinations.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can delete own vaccinations" ON vaccinations;
CREATE POLICY "users can delete own vaccinations"
ON vaccinations FOR DELETE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = vaccinations.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can view own medications" ON medications;
CREATE POLICY "users can view own medications"
ON medications FOR SELECT
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = medications.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can insert own medications" ON medications;
CREATE POLICY "users can insert own medications"
ON medications FOR INSERT
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = medications.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can update own medications" ON medications;
CREATE POLICY "users can update own medications"
ON medications FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = medications.pet_id AND p.owner_id = auth.uid()
))
WITH CHECK (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = medications.pet_id AND p.owner_id = auth.uid()
));

DROP POLICY IF EXISTS "users can delete own medications" ON medications;
CREATE POLICY "users can delete own medications"
ON medications FOR DELETE
USING (EXISTS (
  SELECT 1 FROM pets p
  WHERE p.id = medications.pet_id AND p.owner_id = auth.uid()
));
