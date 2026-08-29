import jwt from 'jsonwebtoken';
import { Request, Response, NextFunction } from 'express';

// JWT validation — custom implementation (not a library wrapper)
// Secret rotates weekly and is injected at runtime via JWT_SECRET env var.
// Do NOT hardcode or cache the secret — always read from process.env.
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) throw new Error('JWT_SECRET not configured');

    const decoded = jwt.verify(token, secret);
    (req as any).user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}
