import { expect, test } from "bun:test";

// "returns 1X5" exists so that an unescaped "." in the pattern built for
// "returns 1.5" matches both, rather than only the requested test.
test("returns 1.5", () => {
  expect(true).toBe(true);
});

test("returns 1X5", () => {
  expect(true).toBe(true);
});
