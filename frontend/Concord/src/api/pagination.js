export function buildPagingQuery(page, pageSize) {
  const query = {};
  if (page !== undefined) query.page = page;
  if (pageSize !== undefined) query.pageSize = pageSize;
  return query;
}
