/** Small, fixed-step springs for decorative surfaces; never drives setup state. */
const STEP = 1 / 120;
const MAX_FRAME = 0.05;

export function createSpring(position = 0) {
  return { position, velocity: 0, remainder: 0 };
}

export function advanceSpring(
  state,
  target,
  elapsed,
  stiffness = 220,
  damping = 26,
) {
  let { position, velocity } = state;
  let remaining = state.remainder + Math.max(0, Math.min(MAX_FRAME, elapsed));
  while (remaining + Number.EPSILON >= STEP) {
    velocity += (stiffness * (target - position) - damping * velocity) * STEP;
    position += velocity * STEP;
    remaining -= STEP;
  }
  return { position, velocity, remainder: Math.max(0, remaining) };
}

export function springSettled(state, target) {
  return (
    Math.abs(state.position - target) < 0.08 && Math.abs(state.velocity) < 0.3
  );
}

/** Deform the material alone. Reciprocal axes keep projected area constant. */
export function surfaceStretch(vx, vy, maximum = 0.12) {
  const scaleX = 1 + Math.min(maximum, Math.hypot(vx, vy) * 0.00025);
  return {
    angle: (Math.atan2(vy, vx) * 180) / Math.PI,
    scaleX,
    scaleY: 1 / scaleX,
  };
}
