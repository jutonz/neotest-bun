import { describe, expect, test } from "bun:test";

describe("the describe block", () => {
  test("the test", () => {
    expect(true).toBe(true);
  });
});
