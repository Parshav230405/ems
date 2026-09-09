import { Request } from 'express';

/**
 * Returns the authenticated client ID strictly from req.user.
 * Client ID is derived solely from the cryptographically verified JWT.
 */
export function getTenantId(req: Request): number {
  if (!req.user || !req.user.clientId) {
    throw new Error('Tenant context missing: user is not authenticated with a valid client ID');
  }
  return req.user.clientId;
}

/**
 * Builds a Prisma `where` clause strictly scoped to the requesting tenant.
 */
export function whereTenant<T extends object>(req: Request, filter: T = {} as T): T & { clientId: number } {
  const clientId = getTenantId(req);
  return {
    ...filter,
    clientId,
  };
}

/**
 * Strips any user-provided tenant identifiers from request body and query.
 * This guarantees client_id cannot be spoofed or overridden in requests.
 */
export function sanitizeTenantInput(body: any): any {
  if (!body || typeof body !== 'object') return body;
  const clone = { ...body };
  delete clone.clientId;
  delete clone.client_id;
  delete clone.tenantId;
  delete clone.tenant_id;
  return clone;
}
