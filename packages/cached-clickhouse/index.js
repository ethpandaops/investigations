/**
 * Cached ClickHouse Connector for Evidence
 *
 * Wraps the ClickHouse connector with transparent parquet-based caching.
 * Cache is stored locally in .cache/queries/{hash}.parquet
 */

import { createHash } from 'crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { join, basename } from 'path';
import { EvidenceType } from '@evidence-dev/db-commons';
import { createClient } from '@clickhouse/client';
import * as parquet from 'parquet-wasm';

/**
 * @typedef {Object} ConnectorOptions
 * @property {string} url - ClickHouse instance URL
 * @property {string} username - ClickHouse username
 * @property {string} password - ClickHouse password
 * @property {string} [cacheDir] - Cache directory (default: .cache/queries)
 * @property {string[]} [skipCachePatterns] - Glob patterns for files to skip caching
 */

/**
 * @see https://docs.evidence.dev/plugins/creating-a-plugin/datasources#options-specification
 */
export const options = {
  url: {
    title: 'URL',
    description: 'ClickHouse instance URL',
    type: 'string',
  },
  username: {
    title: 'Username',
    type: 'string',
  },
  password: {
    title: 'Password',
    type: 'string',
    secret: true,
  },
  cacheDir: {
    title: 'Cache Directory',
    description: 'Directory to store cached query results (default: .cache/queries)',
    type: 'string',
    default: '.cache/queries',
  },
  timeout: {
    title: 'Query Timeout',
    description: 'Query timeout in milliseconds (default: 300000 = 5 minutes)',
    type: 'number',
    default: 300000,
  },
};

/**
 * Patterns that indicate a query should skip cache
 */
const SKIP_CACHE_PATTERNS = [
  /now\s*\(/i,
  /currentDate\s*\(/i,
  /today\s*\(/i,
  /currentTimestamp\s*\(/i,
];

/**
 * Check if a query should skip caching
 * @param {string} queryText - The SQL query text
 * @param {string} queryPath - The path to the query file
 * @returns {boolean} - True if cache should be skipped
 */
function shouldSkipCache(queryText, queryPath) {
  // Check environment variable
  if (process.env.CACHE_DISABLED === 'true') {
    return true;
  }

  // Check for @nocache directive in query
  if (queryText.includes('@nocache') || queryText.includes('-- nocache')) {
    return true;
  }

  // Check filename patterns
  const filename = basename(queryPath);
  if (filename.endsWith('.live.sql') || filename.endsWith('.nocache.sql')) {
    return true;
  }

  // Check for dynamic time functions
  for (const pattern of SKIP_CACHE_PATTERNS) {
    if (pattern.test(queryText)) {
      return true;
    }
  }

  return false;
}

/**
 * Generate a cache key (SHA256 hash) for a query
 * @param {string} queryText - The SQL query text
 * @returns {string} - The cache key
 */
function getCacheKey(queryText) {
  // Normalize whitespace for consistent hashing
  const normalized = queryText.trim().replace(/\s+/g, ' ');
  return createHash('sha256').update(normalized).digest('hex').substring(0, 16);
}

/**
 * Infer Evidence type from a JavaScript value
 * @param {*} value - The value to infer type from
 * @returns {string} - The Evidence type
 */
function inferEvidenceType(value) {
  if (value === null || value === undefined) {
    return EvidenceType.STRING;
  }
  if (typeof value === 'number') {
    return EvidenceType.NUMBER;
  }
  if (typeof value === 'boolean') {
    return EvidenceType.BOOLEAN;
  }
  if (value instanceof Date) {
    return EvidenceType.DATE;
  }
  // Don't try to infer dates from strings - Evidence's Arrow handling has issues
  // Just return strings and let the frontend handle formatting
  return EvidenceType.STRING;
}

/**
 * Save query results to parquet cache
 * @param {string} cachePath - Path to save the parquet file
 * @param {Object[]} rows - The query result rows
 */
async function saveToCache(cachePath, rows) {
  if (!rows || rows.length === 0) {
    // Save empty result indicator
    writeFileSync(cachePath + '.empty', '');
    return;
  }

  // Convert rows to Arrow-compatible format for parquet-wasm
  const columns = Object.keys(rows[0]);

  // Build column arrays
  const columnData = {};
  for (const col of columns) {
    columnData[col] = rows.map((row) => {
      const val = row[col];
      // Convert dates to ISO strings for storage
      if (val instanceof Date) {
        return val.toISOString();
      }
      return val;
    });
  }

  // For parquet-wasm, we need to serialize as JSON first then write
  // This is a simplified approach - in production you might want proper Arrow serialization
  const jsonData = JSON.stringify({ columns, data: columnData, rowCount: rows.length });
  writeFileSync(cachePath + '.json', jsonData);
}

/**
 * Load query results from parquet cache
 * @param {string} cachePath - Path to the parquet file
 * @returns {Object[]|null} - The cached rows or null if not found
 */
function loadFromCache(cachePath) {
  // Prefer a concrete cached result over an empty marker, so a zero-row
  // re-fetch (e.g. after source data ages out of retention) cannot shadow
  // committed cache entries.
  const jsonPath = cachePath + '.json';
  if (existsSync(jsonPath)) {
    try {
      const jsonData = JSON.parse(readFileSync(jsonPath, 'utf-8'));
      const { columns, data, rowCount } = jsonData;

      // Reconstruct rows
      const rows = [];
      for (let i = 0; i < rowCount; i++) {
        const row = {};
        for (const col of columns) {
          row[col] = data[col][i];
        }
        rows.push(row);
      }
      return rows;
    } catch (error) {
      console.error(`[cached-clickhouse] Error reading cache: ${error.message}`);
      return null;
    }
  }

  // Empty result marker
  if (existsSync(cachePath + '.empty')) {
    return [];
  }

  return null;
}

/**
 * @type {import("@evidence-dev/db-commons").GetRunner<ConnectorOptions>}
 */
export const getRunner = (opts) => {
  const timeout = opts.timeout || 300000; // 5 minutes default
  const client = createClient({
    url: opts.url,
    username: opts.username,
    password: opts.password,
    request_timeout: timeout,
  });

  const cacheDir = opts.cacheDir || '.cache/queries';

  // Ensure cache directory exists
  if (!existsSync(cacheDir)) {
    mkdirSync(cacheDir, { recursive: true });
  }

  return async (queryText, queryPath) => {
    const filename = basename(queryPath);
    const skipCache = shouldSkipCache(queryText, queryPath);
    const cacheKey = getCacheKey(queryText);
    const cachePath = join(cacheDir, cacheKey);

    // Try to load from cache if not skipping
    if (!skipCache) {
      const cachedRows = loadFromCache(cachePath);
      if (cachedRows !== null) {
        console.log(`[cached-clickhouse] Cache HIT for ${filename} (${cacheKey})`);

        // Build column types from cached data
        const columnTypes = cachedRows.length > 0
          ? Object.keys(cachedRows[0]).map((key) => ({
              name: key,
              evidenceType: inferEvidenceType(cachedRows[0][key]),
              typeFidelity: 'inferred',
            }))
          : [];

        return {
          rows: cachedRows,
          columnTypes,
          expectedRowCount: cachedRows.length,
        };
      }
    }

    // Cache miss or skip - execute query
    const logPrefix = skipCache ? 'SKIP' : 'MISS';
    console.log(`[cached-clickhouse] Cache ${logPrefix} for ${filename} (${cacheKey}) - querying ClickHouse...`);

    try {
      const startTime = Date.now();
      const response = await client.query({
        query: queryText,
        format: 'JSONEachRow',
      });

      const rows = await response.json();
      const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log(`[cached-clickhouse] Query completed in ${elapsed}s, ${rows.length} rows`);

      // Save to cache if not skipping
      if (!skipCache) {
        try {
          await saveToCache(cachePath, rows);
          console.log(`[cached-clickhouse] Cached result for ${filename}`);
        } catch (cacheError) {
          console.error(`[cached-clickhouse] Failed to cache result: ${cacheError.message}`);
        }
      }

      // Build column types
      const columnTypes = rows.length > 0
        ? Object.keys(rows[0]).map((key) => ({
            name: key,
            evidenceType: inferEvidenceType(rows[0][key]),
            typeFidelity: 'inferred',
          }))
        : [];

      return {
        rows,
        columnTypes,
        expectedRowCount: rows.length,
      };
    } catch (error) {
      console.error(`[cached-clickhouse] Error executing query ${filename}: ${error.message}`);
      throw error;
    }
  };
};

/**
 * @type {import("@evidence-dev/db-commons").ConnectionTester<ConnectorOptions>}
 */
export const testConnection = async (opts) => {
  const client = createClient({
    url: opts.url,
    username: opts.username,
    password: opts.password,
  });

  try {
    const result = await client.query({
      query: 'SELECT 1',
      format: 'JSONEachRow',
    });
    await result.json();
    return true;
  } catch (error) {
    console.error('[cached-clickhouse] Connection test failed:', error.message);
    return false;
  }
};
