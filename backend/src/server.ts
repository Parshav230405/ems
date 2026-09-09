import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import apiRouter from './routes/api.router';
import { errorHandler } from './middleware/error.middleware';

dotenv.config();

export const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Mount all API endpoints under /api
app.use('/api', apiRouter);

// Serve Flutter Web production frontend
const candidatePaths = [
  path.resolve(__dirname, '../../frontend/build/web'),
  path.resolve(__dirname, '../public'),
  path.resolve(__dirname, '../../backend/public'),
  path.resolve(process.cwd(), 'public'),
  path.resolve(process.cwd(), 'backend/public'),
];
const frontendPath = candidatePaths.find((p) => fs.existsSync(p));
if (frontendPath) {
  app.use(express.static(frontendPath));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api')) return next();
    res.sendFile(path.join(frontendPath, 'index.html'));
  });
}

// Global Error Handler
app.use(errorHandler);

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`===========================================`);
    console.log(` AURA EMS Full-Stack Application Running`);
    console.log(` URL:    http://localhost:${PORT}`);
    console.log(` Health: http://localhost:${PORT}/api/health`);
    console.log(`===========================================`);
  });
}

export default app;
