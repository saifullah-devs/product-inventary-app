import { Request, Response, NextFunction } from 'express';

export const apiKeyAuth = (req: Request, res: Response, next: NextFunction) => {
  const userKey = req.headers['x-api-key'];
  const masterKey = process.env.API_KEY;

  if (!userKey || userKey !== masterKey) {
     res.status(401).json({ error: 'Unauthorized: Invalid or missing API key' });
     return;
  }

  next();
};