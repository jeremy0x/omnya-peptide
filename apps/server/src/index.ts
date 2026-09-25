import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import { z } from 'zod';
import { store } from './store.js';
import { CircleMember } from './types.js';
import { pushUserDataToSupabase } from './supabase.js';

export async function buildApp() {
  const app = Fastify({ logger: false });

  await app.register(cors, { origin: '*' });
  await app.register(helmet, { contentSecurityPolicy: false });

  // Health Check
  app.get('/health', async () => {
    return { status: 'ok', service: 'omnya-peptide-api', timestamp: new Date().toISOString() };
  });

  // Auth: Anonymous Device Registration
  app.post('/api/v1/auth/anonymous', async (req, reply) => {
    const schema = z.object({
      deviceId: z.string().min(3),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid deviceId' });
    }

    const user = store.getOrCreateUser(parsed.data.deviceId);
    return {
      token: `omnya_tok_${user.id}`,
      user,
    };
  });

  // Auth: Claim Account with Email / Apple ID
  app.post('/api/v1/auth/claim', async (req, reply) => {
    const schema = z.object({
      userId: z.string(),
      email: z.string().email(),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid email or userId' });
    }

    const user = store.users.get(parsed.data.userId);
    if (!user) {
      return reply.status(404).send({ error: 'User not found' });
    }

    user.email = parsed.data.email;
    user.updatedAt = new Date().toISOString();
    return { user };
  });

  // Sync: Push Client Data to Cloud
  app.post('/api/v1/sync/push', async (req, reply) => {
    const schema = z.object({
      userId: z.string(),
      compounds: z.array(z.any()).optional(),
      doseLogs: z.array(z.any()).optional(),
      checkIns: z.array(z.any()).optional(),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid sync payload' });
    }

    const { userId, compounds, doseLogs, checkIns } = parsed.data;
    if (compounds) store.compounds.set(userId, compounds);
    if (doseLogs) store.doseLogs.set(userId, doseLogs);
    if (checkIns) store.checkIns.set(userId, checkIns);

    // If Supabase is configured via env vars, persist to PostgreSQL
    await pushUserDataToSupabase(userId, { compounds, doseLogs, checkIns });

    return {
      success: true,
      syncedAt: new Date().toISOString(),
      counts: {
        compounds: compounds?.length ?? 0,
        doseLogs: doseLogs?.length ?? 0,
        checkIns: checkIns?.length ?? 0,
      },
    };
  });

  // Sync: Pull Client Data
  app.get('/api/v1/sync/pull', async (req, reply) => {
    const { userId } = req.query as { userId?: string };
    if (!userId) {
      return reply.status(400).send({ error: 'Missing userId parameter' });
    }

    return {
      userId,
      compounds: store.compounds.get(userId) || [],
      doseLogs: store.doseLogs.get(userId) || [],
      checkIns: store.checkIns.get(userId) || [],
      pulledAt: new Date().toISOString(),
    };
  });

  // Circles: Create an invite-only circle (max 5 members)
  app.post('/api/v1/circles/create', async (req, reply) => {
    const schema = z.object({
      userId: z.string(),
      name: z.string().min(2),
      displayName: z.string().min(1),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid circle creation parameters' });
    }

    const { userId, name, displayName } = parsed.data;
    const circleId = `circ_${Date.now()}`;
    // Generate clean 5-character alphanumeric invite code
    const inviteCode = Math.random().toString(36).substring(2, 7).toUpperCase();

    const member: CircleMember = {
      userId,
      displayName,
      avatarLetter: displayName.trim().charAt(0).toUpperCase() || 'U',
      checkedInToday: true,
      weeklyDosesLogged: 1,
      weeklyDosesTarget: 7,
      lastActive: new Date().toISOString(),
    };

    const circle = {
      id: circleId,
      inviteCode,
      name,
      creatorId: userId,
      maxMembers: 5,
      createdAt: new Date().toISOString(),
      members: [member],
    };

    store.circles.set(circleId, circle);
    store.inviteCodeMap.set(inviteCode, circleId);

    return { circle };
  });

  // Circles: Join with invite code (enforces 5 max)
  app.post('/api/v1/circles/join', async (req, reply) => {
    const schema = z.object({
      userId: z.string(),
      inviteCode: z.string().min(3),
      displayName: z.string().min(1),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid join parameters' });
    }

    const { userId, inviteCode, displayName } = parsed.data;
    const cleanCode = inviteCode.trim().toUpperCase();
    const circleId = store.inviteCodeMap.get(cleanCode);

    if (!circleId || !store.circles.has(circleId)) {
      return reply.status(404).send({ error: 'Invite code not found' });
    }

    const circle = store.circles.get(circleId)!;
    if (circle.members.length >= circle.maxMembers) {
      return reply.status(400).send({ error: 'This circle is full (maximum 5 members).' });
    }

    const existingMember = circle.members.find((m) => m.userId === userId);
    if (!existingMember) {
      circle.members.push({
        userId,
        displayName,
        avatarLetter: displayName.trim().charAt(0).toUpperCase() || 'U',
        checkedInToday: false,
        weeklyDosesLogged: 0,
        weeklyDosesTarget: 7,
        lastActive: new Date().toISOString(),
      });
    }

    return { circle };
  });

  // Circles: Fetch Circle details (weights strictly hidden by design)
  app.get('/api/v1/circles/:id', async (req, reply) => {
    const { id } = req.params as { id: string };
    const circle = store.circles.get(id);

    if (!circle) {
      return reply.status(404).send({ error: 'Circle not found' });
    }

    const checkedInCount = circle.members.filter((m) => m.checkedInToday).length;
    return {
      circle: {
        ...circle,
        checkedInSummary: `${checkedInCount} of ${circle.members.length} checked in today`,
      },
    };
  });

  // Circles: Fetch circle for a specific user
  app.get('/api/v1/circles/user/:userId', async (req, reply) => {
    const { userId } = req.params as { userId: string };
    for (const circle of store.circles.values()) {
      if (circle.members.some((m) => m.userId === userId)) {
        return { circle };
      }
    }
    return reply.status(404).send({ error: 'Circle not found for user' });
  });

  // Circles: Update member check-in progress
  app.post('/api/v1/circles/:id/progress', async (req, reply) => {
    const { id } = req.params as { id: string };
    const schema = z.object({
      userId: z.string(),
      checkedInToday: z.boolean(),
      weeklyDosesLogged: z.number(),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'Invalid progress payload' });
    }

    const circle = store.circles.get(id);
    if (!circle) {
      return reply.status(404).send({ error: 'Circle not found' });
    }

    const member = circle.members.find((m) => m.userId === parsed.data.userId);
    if (member) {
      member.checkedInToday = parsed.data.checkedInToday;
      member.weeklyDosesLogged = parsed.data.weeklyDosesLogged;
      member.lastActive = new Date().toISOString();
    }

    return { success: true, circle };
  });

  // RevenueCat Webhook: Pro Subscription handler
  app.post('/api/v1/webhooks/revenuecat', async (req, reply) => {
    const payload = req.body as any;
    const appUserId = payload?.event?.app_user_id;
    const type = payload?.event?.type;

    if (appUserId && store.users.has(appUserId)) {
      const user = store.users.get(appUserId)!;
      if (type === 'INITIAL_PURCHASE' || type === 'RENEWAL') {
        user.isPro = true;
      } else if (type === 'EXPIRATION') {
        user.isPro = false;
      }
      user.updatedAt = new Date().toISOString();
    }

    return { received: true };
  });

  return app;
}

if (process.env.NODE_ENV !== 'test') {
  const start = async () => {
    const app = await buildApp();
    const port = Number(process.env.PORT) || 3000;
    try {
      await app.listen({ port, host: '0.0.0.0' });
      console.log(`Omnya Peptide API running on http://localhost:${port}`);
    } catch (err) {
      console.error(err);
      process.exit(1);
    }
  };
  start();
}
