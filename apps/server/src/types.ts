export interface DeviceUser {
  id: string;
  deviceId: string;
  email?: string;
  isPro: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CompoundRecord {
  id: string;
  name: string;
  nickname?: string;
  category: 'body' | 'glow_skin' | 'heal_recover' | 'glowAndSkin' | 'healAndRecover';
  doseMg: number;
  frequencyDays: number;
  targetSite?: string;
  injectionSite?: string;
  vialMg: number;
  bacWaterMl: number;
  dosesLeft: number;
  costPerDose: number;
  totalMonthlyCost: number;
  startDate: string;
  runoutDate: string;
}

export interface SyncCompoundInput {
  id: string;
  name: string;
  nickname?: string;
  category: string;
  doseMg: number;
  frequencyDays?: number;
  injectionSite?: string;
  targetSite?: string;
  vialMg?: number;
  bacWaterMl?: number;
  dosesLeft?: number;
  costPerDose?: number;
  totalMonthlyCost?: number;
  startDate?: string;
  runoutDate?: string;
}

export interface DoseLogRecord {
  id: string;
  compoundId: string;
  compoundName: string;
  doseMg: number;
  injectionSite: string;
  timestamp: string;
  synced?: boolean;
}

export interface SyncDoseLogInput {
  id: string;
  compoundId: string;
  compoundName: string;
  doseMg: number;
  injectionSite: string;
  timestamp: string;
  synced?: boolean;
}

export interface CheckInRecord {
  id: string;
  date: string;
  energyLevel: number; // 1-5
  appetiteLevel: number; // 1-5
  photoTaken?: boolean;
  weightLbs?: number;
  waistInches?: number;
  cyclePhase?: 'follicular' | 'ovulation' | 'luteal' | 'menstruation';
  isPeriodDay?: boolean;
  localPhotoPath?: string;
  notes?: string;
}

export interface SyncCheckInInput {
  id: string;
  date: string;
  energyLevel: number;
  appetiteLevel: number;
  photoTaken?: boolean;
  weightLbs?: number;
  waistInches?: number;
  cyclePhase?: 'follicular' | 'ovulation' | 'luteal' | 'menstruation';
  isPeriodDay?: boolean;
  localPhotoPath?: string;
  notes?: string;
}

export interface CircleMember {
  userId: string;
  displayName: string;
  avatarLetter: string;
  checkedInToday: boolean;
  weeklyDosesLogged: number;
  weeklyDosesTarget: number;
  lastActive: string;
}

export interface CircleGroup {
  id: string;
  inviteCode: string;
  name: string;
  creatorId: string;
  members: CircleMember[];
  maxMembers: number;
  createdAt: string;
}
