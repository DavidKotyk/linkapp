const express = require('express');
const { chromium } = require('playwright');

const app = express();
const port = process.env.PORT || 8000;

// Demo scraper function: navigate to example.com and return its title
async function scrapeDemo(city) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  // For now, ignore the city parameter and scrape example.com
  await page.goto('https://example.com', { waitUntil: 'networkidle' });
  const title = await page.title();
  await browser.close();
  return [
    { site: 'example.com', title, city }
  ];
}

app.get('/events', async (req, res) => {
  const city = req.query.city || 'Unknown';
  try {
    const data = await scrapeDemo(city);
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.listen(port, () => {
  console.log(`FacebookScraper listening on port ${port}`);
});