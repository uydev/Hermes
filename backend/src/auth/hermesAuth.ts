import jwt from 'jsonwebtoken';
import { type Env } from '../env';

export type HermesClaims = {
  sub: string;
  displayName: string;
  room: string;
  role: 'host' | 'participant';
  iat?: number;
  exp?: number;
  iss?: string;
  aud?: string | string[];
};

export function requireHermesJwtSigningKey(env: Env): string {
  const key = env.HERMES_JWT_SIGNING_KEY;
  if (!key || key.trim().length < 16) {
    throw new Error(
      'Server misconfigured: HERMES_JWT_SIGNING_KEY must be set (min 16 chars) to verify guest tokens.',
    );
  }
  return key;
}

export function getBearerToken(authorization?: string): string | null {
  if (!authorization) return null;
  const m = authorization.match(/^Bearer\s+(.+)$/i);
  return m?.[1] ?? null;
}

export function verifyHermesToken(token: string, env: Env): HermesClaims {
  const key = requireHermesJwtSigningKey(env);

  const decoded = jwt.verify(token, key, {
    issuer: 'hermes-backend',
    audience: 'hermes-client',
  });

  if (typeof decoded !== 'object' || decoded === null) {
    throw new Error('Invalid Hermes token');
  }

  const sub = (decoded.sub ?? '') as string;
  const displayName = (decoded.displayName ?? '') as string;
  const room = (decoded.room ?? '') as string;
  const role = (decoded.role ?? '') as string;

  if (!sub || !displayName || !room || (role !== 'host' && role !== 'participant')) {
    throw new Error('Invalid Hermes token claims');
  }

  const claims: HermesClaims = {
    sub,
    displayName,
    room,
    role,
  };

  if (typeof decoded.iat === 'number') claims.iat = decoded.iat;
  if (typeof decoded.exp === 'number') claims.exp = decoded.exp;
  if (typeof decoded.iss === 'string') claims.iss = decoded.iss;
  if (decoded.aud !== undefined) claims.aud = decoded.aud as any;

  return claims;
}
