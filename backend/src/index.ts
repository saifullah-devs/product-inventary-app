import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import apiRouter from './routes.js';

dotenv.config();

const app = express();
const port = parseInt(process.env.PORT || '4000', 10);

app.use(cors({ origin: true }));
app.use(express.json());
app.use('/api', apiRouter);

app.get('/', (_req, res) => {
  res.json({ message: 'Product Inventory Backend is running' });
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});
