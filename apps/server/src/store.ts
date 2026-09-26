import { DeviceUser, CompoundRecord, DoseLogRecord, CheckInRecord, CircleGroup, SyncCompoundInput, SyncDoseLogInput, SyncCheckInInput } from './types.js';

export function generateCleanInviteCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 5; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

class InMemoryStore {
  public users: Map<string, DeviceUser> = new Map();
  public compounds: Map<string, (CompoundRecord | SyncCompoundInput)[]> = new Map(); // userId -> compounds
  public doseLogs: Map<string, (DoseLogRecord | SyncDoseLogInput)[]> = new Map(); // userId -> dose logs
  public checkIns: Map<string, (CheckInRecord | SyncCheckInInput)[]> = new Map(); // userId -> check-ins
  public circles: Map<string, CircleGroup> = new Map(); // circleId -> CircleGroup
  public inviteCodeMap: Map<string, string> = new Map(); // inviteCode -> circleId
  public userInviteCodes: Map<string, string> = new Map(); // userId -> unique assigned inviteCode

  constructor() {
    this.seedDemoData();
  }

  public getOrCreateUserInviteCode(userId: string, circleId?: string): string {
    if (this.userInviteCodes.has(userId)) {
      const existing = this.userInviteCodes.get(userId)!;
      if (circleId) {
        this.inviteCodeMap.set(existing, circleId);
      }
      return existing;
    }

    let code: string;
    do {
      code = generateCleanInviteCode();
    } while (this.inviteCodeMap.has(code));

    this.userInviteCodes.set(userId, code);
    if (circleId) {
      this.inviteCodeMap.set(code, circleId);
    }
    return code;
  }

  private seedDemoData() {
    const demoCircleId = 'circle_demo_01';
    // Generate clean unique invite codes for the demo cohort
    const miaCode = this.getOrCreateUserInviteCode('user_mia', demoCircleId);
    this.getOrCreateUserInviteCode('user_you', demoCircleId);
    this.getOrCreateUserInviteCode('usr_local_seed', demoCircleId);
    
    const demoCircle: CircleGroup = {
      id: demoCircleId,
      inviteCode: miaCode,
      name: "Sunday Glow Cohort",
      creatorId: "user_mia",
      maxMembers: 5,
      createdAt: new Date().toISOString(),
      members: [
        {
          userId: "user_mia",
          displayName: "Mia",
          avatarLetter: "M",
          checkedInToday: true,
          weeklyDosesLogged: 7,
          weeklyDosesTarget: 7,
          lastActive: new Date().toISOString()
        },
        {
          userId: "user_sarah",
          displayName: "Sarah",
          avatarLetter: "S",
          checkedInToday: true,
          weeklyDosesLogged: 6,
          weeklyDosesTarget: 7,
          lastActive: new Date().toISOString()
        },
        {
          userId: "user_jess",
          displayName: "Jess",
          avatarLetter: "J",
          checkedInToday: true,
          weeklyDosesLogged: 5,
          weeklyDosesTarget: 7,
          lastActive: new Date().toISOString()
        },
        {
          userId: "user_ava",
          displayName: "Ava",
          avatarLetter: "A",
          checkedInToday: true,
          weeklyDosesLogged: 6,
          weeklyDosesTarget: 7,
          lastActive: new Date().toISOString()
        }
      ]
    };

    this.circles.set(demoCircleId, demoCircle);
    this.inviteCodeMap.set(miaCode, demoCircleId);
  }

  getOrCreateUser(deviceId: string): DeviceUser {
    for (const user of this.users.values()) {
      if (user.deviceId === deviceId) {
        return user;
      }
    }
    const newUser: DeviceUser = {
      id: `usr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      deviceId,
      isPro: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    this.users.set(newUser.id, newUser);
    return newUser;
  }
}

export const store = new InMemoryStore();
