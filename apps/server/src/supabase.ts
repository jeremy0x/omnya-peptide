import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { SyncCompoundInput, SyncDoseLogInput, SyncCheckInInput } from './types.js';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '';

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseKey);

export const supabase: SupabaseClient | null = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    })
  : null;

export async function pushUserDataToSupabase(
  userId: string,
  data: {
    compounds?: SyncCompoundInput[];
    doseLogs?: SyncDoseLogInput[];
    checkIns?: SyncCheckInInput[];
  }
): Promise<boolean> {
  if (!supabase) return false;

  try {
    // Ensure profile exists for foreign key constraint
    await supabase.from('profiles').upsert({
      id: userId,
      updated_at: new Date().toISOString(),
    });

    if (data.compounds && data.compounds.length > 0) {
      const records = data.compounds.map((c) => ({
        id: c.id,
        user_id: userId,
        name: c.name,
        nickname: c.nickname,
        category: c.category,
        dose_mg: c.doseMg,
        frequency_days: c.frequencyDays ?? 1,
        injection_site: c.injectionSite ?? 'Left thigh',
        vial_mg: c.vialMg ?? 10.0,
        bac_water_ml: c.bacWaterMl ?? 2.0,
        doses_left: c.dosesLeft ?? 0,
        cost_per_dose: c.costPerDose ?? 0.0,
        total_monthly_cost: c.totalMonthlyCost ?? 0.0,
        start_date: c.startDate,
        runout_date: c.runoutDate,
      }));
      await supabase.from('compounds').upsert(records);
    }

    if (data.doseLogs && data.doseLogs.length > 0) {
      const records = data.doseLogs.map((d) => ({
        id: d.id,
        user_id: userId,
        compound_id: d.compoundId,
        compound_name: d.compoundName,
        dose_mg: d.doseMg,
        injection_site: d.injectionSite,
        timestamp: d.timestamp,
      }));
      await supabase.from('dose_logs').upsert(records);
    }

    if (data.checkIns && data.checkIns.length > 0) {
      const records = data.checkIns.map((k) => ({
        id: k.id,
        user_id: userId,
        date: k.date,
        energy_level: k.energyLevel,
        appetite_level: k.appetiteLevel,
        weight_lbs: k.weightLbs,
        waist_inches: k.waistInches,
        cycle_phase: k.cyclePhase,
        is_period_day: k.isPeriodDay ?? false,
        photo_url: k.localPhotoPath,
        notes: k.notes,
      }));
      await supabase.from('check_ins').upsert(records);
    }

    return true;
  } catch (err) {
    console.error('Supabase sync error:', err);
    return false;
  }
}
