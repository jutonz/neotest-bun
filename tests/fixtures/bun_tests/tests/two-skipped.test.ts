import { expect, test } from "bun:test";

test.skip("first", () => {
  expect(true).toBe(false);
});

test.skip("second", () => {
  expect(true).toBe(false);
});
