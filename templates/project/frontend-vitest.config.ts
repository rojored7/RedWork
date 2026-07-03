// RedWork project template - frontend coverage contract.
// Acceptance is 100%, always: the slice gate, wave gate and CI all run
//   vitest run --coverage
// Thresholds live HERE (single source of truth); the CLI flag only enables
// collection. The exclude list is part of the reviewed contract: config and
// entrypoint wiring only. Agents 15/16 MUST NOT extend it to make coverage
// pass — write the missing test instead.

import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: [
        "src/main.tsx",        // app entrypoint (render wiring)
        "src/vite-env.d.ts",
        "src/**/*.d.ts",
      ],
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100,
      },
    },
  },
});
