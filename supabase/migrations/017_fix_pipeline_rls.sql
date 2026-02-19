-- 017 · Fix recruiting_pipeline RLS INSERT policy
-- FOR ALL with only USING clause blocks INSERT — need WITH CHECK too

DROP POLICY IF EXISTS "pipeline_own" ON recruiting_pipeline;

CREATE POLICY "pipeline_own" ON recruiting_pipeline FOR ALL
  USING (EXISTS (SELECT 1 FROM coaches WHERE id = recruiting_pipeline.coach_id AND user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM coaches WHERE id = recruiting_pipeline.coach_id AND user_id = auth.uid()));
