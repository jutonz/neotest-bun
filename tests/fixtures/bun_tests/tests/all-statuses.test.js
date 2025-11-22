import { expect, test } from "bun:test";

test("pass", () => {
  expect(true).toBe(true);
});

test.skip("skip", () => {
  expect(true).toBe(true);
});

test("fail", () => {
  expect(true).toBe(false);
});
