#!/usr/bin/env node

/**
 * Admin helper to set Firebase Auth custom claims.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *   node scripts/set-custom-claims.mjs --uid "<firebase-uid>" --role "admin"
 *
 * Optional:
 *   --project "<firebase-project-id>"
 *
 * Notes:
 * - Requires `firebase-admin`:
 *     npm install firebase-admin
 * - Role is validated against: student, warden, admin
 */

import process from 'node:process';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const ALLOWED_ROLES = new Set(['student', 'warden', 'admin']);

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const value = argv[i + 1];
      if (!value || value.startsWith('--')) {
        throw new Error(`Missing value for --${key}`);
      }
      args[key] = value;
      i += 1;
    }
  }
  return args;
}

function usage() {
  console.log(
    [
      'Usage:',
      '  node scripts/set-custom-claims.mjs --uid "<firebase-uid>" --role "student|warden|admin" [--project "<project-id>"]',
      '',
      'Auth options:',
      '  1) Set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON path, or',
      '  2) Use workload identity / application default credentials in CI.',
    ].join('\n'),
  );
}

async function main() {
  try {
    const args = parseArgs(process.argv.slice(2));
    const uid = args.uid;
    const role = args.role;
    const projectId = args.project;

    if (!uid || !role) {
      usage();
      process.exitCode = 1;
      return;
    }

    if (!ALLOWED_ROLES.has(role)) {
      throw new Error(`Invalid role "${role}". Allowed: ${Array.from(ALLOWED_ROLES).join(', ')}`);
    }

    // Prefer ADC by default; allow explicit project override.
    initializeApp({
      credential: applicationDefault(),
      ...(projectId ? { projectId } : {}),
    });

    const auth = getAuth();
    await auth.setCustomUserClaims(uid, { role });

    // Optional: force token refresh awareness in logs.
    const user = await auth.getUser(uid);
    console.log(`Custom claims updated for uid=${uid}.`);
    console.log(`email=${user.email ?? 'n/a'} role=${role}`);
    console.log('Ask the user to sign out/in (or refresh ID token) to pick up claims.');
  } catch (error) {
    console.error('Failed to set custom claims.');
    console.error(error instanceof Error ? error.message : error);
    process.exitCode = 1;
  }
}

main();
