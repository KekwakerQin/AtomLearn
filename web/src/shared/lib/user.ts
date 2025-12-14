export function getDisplayNameFromEmail(email: string | null): string {
  if (!email) return "user";
  return email.split("@")[0];
}

export function generateUsername(base: string): string {
  return base.toLowerCase().replace(/[^a-z0-9]/g, "");
}

export function randomAbBucket(): "A" | "B" | "C" {
  const buckets = ["A", "B", "C"] as const;
  return buckets[Math.floor(Math.random() * buckets.length)];
}
