import { request } from './httpClient';
import { buildPagingQuery } from './pagination';

export async function searchMessages(query, { page, pageSize } = {}) {
  return request('Search/Messages', { query: { query, ...buildPagingQuery(page, pageSize) } });
}
