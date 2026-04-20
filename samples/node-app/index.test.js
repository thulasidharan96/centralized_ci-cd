const test = require('node:test');
const assert = require('node:assert/strict');
const { health } = require('./index');

test('health returns ok status', () => {
  assert.deepEqual(health(), { status: 'ok', service: 'node-sample' });
});
