import { test, describe } from 'node:test';
import assert from 'node:assert';
import { buildApp } from './index.js';

describe('Omnya Peptide API Test Suite', async () => {
  const app = await buildApp();

  test('GET /health returns 200 and healthy status', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });
    assert.strictEqual(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    assert.strictEqual(body.status, 'ok');
    assert.strictEqual(body.service, 'omnya-peptide-api');
  });

  test('POST /api/v1/auth/anonymous registers device and returns token', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/v1/auth/anonymous',
      payload: { deviceId: 'test-device-uuid-999' },
    });
    assert.strictEqual(response.statusCode, 200);
    const body = JSON.parse(response.payload);
    assert.ok(body.token.startsWith('omnya_tok_'));
    assert.strictEqual(body.user.deviceId, 'test-device-uuid-999');
    assert.strictEqual(body.user.isPro, false);
  });

  test('Circles: Create, Fetch, and Join enforces 5 max limit', async () => {
    // 1. Create circle
    const createRes = await app.inject({
      method: 'POST',
      url: '/api/v1/circles/create',
      payload: {
        userId: 'usr_founder',
        name: 'Glow Queens',
        displayName: 'Chloe',
      },
    });
    assert.strictEqual(createRes.statusCode, 200);
    const { circle } = JSON.parse(createRes.payload);
    assert.strictEqual(circle.members.length, 1);
    assert.ok(circle.inviteCode);

    // 2. Add 4 more members to reach cap of 5
    for (let i = 1; i <= 4; i++) {
      const joinRes = await app.inject({
        method: 'POST',
        url: '/api/v1/circles/join',
        payload: {
          userId: `usr_member_${i}`,
          inviteCode: circle.inviteCode,
          displayName: `Member ${i}`,
        },
      });
      assert.strictEqual(joinRes.statusCode, 200);
    }

    // 3. 6th member attempt must be rejected with 400
    const overflowRes = await app.inject({
      method: 'POST',
      url: '/api/v1/circles/join',
      payload: {
        userId: 'usr_member_6',
        inviteCode: circle.inviteCode,
        displayName: 'Member 6',
      },
    });
    assert.strictEqual(overflowRes.statusCode, 400);
    const errBody = JSON.parse(overflowRes.payload);
    assert.ok(errBody.error.includes('maximum 5 members'));
  });

  test('Data Sync: Push and Pull preserve user data', async () => {
    const testUserId = 'usr_sync_test';
    const mockCompounds = [
      { id: 'cmp_1', name: 'Retatrutide', nickname: 'Dream bod, here we come.', doseMg: 2.0 },
    ];
    const mockDoseLogs = [
      { id: 'log_1', compoundId: 'cmp_1', doseMg: 2.0, injectionSite: 'Left thigh' },
    ];

    const pushRes = await app.inject({
      method: 'POST',
      url: '/api/v1/sync/push',
      payload: {
        userId: testUserId,
        compounds: mockCompounds,
        doseLogs: mockDoseLogs,
      },
    });
    assert.strictEqual(pushRes.statusCode, 200);

    const pullRes = await app.inject({
      method: 'GET',
      url: `/api/v1/sync/pull?userId=${testUserId}`,
    });
    assert.strictEqual(pullRes.statusCode, 200);
    const pulled = JSON.parse(pullRes.payload);
    assert.strictEqual(pulled.compounds.length, 1);
    assert.strictEqual(pulled.compounds[0].name, 'Retatrutide');
    assert.strictEqual(pulled.doseLogs.length, 1);
  });
});
