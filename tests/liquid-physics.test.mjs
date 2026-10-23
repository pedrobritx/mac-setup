import test from "node:test";
import assert from "node:assert/strict";
import {
  createSpring,
  advanceSpring,
  springSettled,
  surfaceStretch,
} from "../docs/assets/liquid-physics.mjs";

test("liquid springs follow the same trajectory at 30, 60 and 120 Hz", () => {
  const trajectories = [30, 60, 120].map((rate) => {
    let state = createSpring(0);
    for (let frame = 0; frame < rate; frame++) {
      state = advanceSpring(state, 240, 1 / rate);
    }
    return state;
  });
  for (const state of trajectories) {
    assert.ok(Math.abs(state.position - trajectories[0].position) < 1e-9);
    assert.ok(springSettled(state, 240));
  }
});

test("a suspended frame is bounded and the spring settles after rapid retargeting", () => {
  let state = advanceSpring(createSpring(20), 600, 30);
  assert.ok(state.position > 20 && state.position < 600);
  for (let frame = 0; frame < 240; frame++) {
    state = advanceSpring(state, frame < 30 ? -100 : 80, 1 / 120);
  }
  assert.ok(springSettled(state, 80));
  assert.ok(Number.isFinite(state.velocity));
});

test("the velocity stretch preserves surface area in every travel direction", () => {
  for (const [x, y] of [
    [0, 0],
    [120, 0],
    [-300, 800],
    [5000, -5000],
  ]) {
    const stretch = surfaceStretch(x, y);
    assert.ok(Math.abs(stretch.scaleX * stretch.scaleY - 1) < 1e-12);
    assert.ok(stretch.scaleX <= 1.12);
  }
});
