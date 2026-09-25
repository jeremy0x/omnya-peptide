import { DeviceUser, CompoundRecord, DoseLogRecord, CheckInRecord, CircleGroup } from './types.js';

class InMemoryStore {
  public users: Map<string, DeviceUser> = new Map();
  public compounds: Map<string, CompoundRecord[]> = new Map(); // userId -> compounds
  public doseLogs: Map<string, DoseLogRecord[]> = new Map(); // userId -> dose logs
  public checkIns: Map<string, CheckInRecord[]> = new Map(); // userId -> check-ins
  public circles: Map<string, CircleGroup> = new Map(); // circleId -> CircleGroup
  public inviteCodeMap: Map<string, string> = new Map(); // inviteCode -> circleId

  constructor() {
    this.seedDemoData();
  }

  private seedDemoData() {
    // Seed a demo circle with members as illustrated in product spec page 2:
    // S M J A (Mia 7/7, You 6/7, Jess 5/7 - 4 of 5 checked in today)
    const demoCircleId = 'circle_demo_01';
    const demoInvite = 'OMNYA';
    
    const demoCircle: CircleGroup = {
      id: demoCircleId,
      inviteCode: demoInvite,
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
    this.inviteCodeMap.set(demoInvite, demoCircleId);
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
