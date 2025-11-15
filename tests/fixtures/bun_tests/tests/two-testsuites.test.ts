import { describe, expect, test } from "bun:test";

describe("first suite", () => {
  test.skip("first test", () => {
    expect(true).toBe(true);
  });
});

describe("second suite", () => {
  test.skip("second test", () => {
    expect(true).toBe(true);
  });
});
