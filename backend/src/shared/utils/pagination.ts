export interface PaginationParams {
  page: number
  limit: number
  skip: number
}

export function parsePagination(
  query: { page?: string; limit?: string },
  maxLimit = 50,
): PaginationParams {
  const page = Math.max(1, parseInt(query.page || '1'))
  const limit = Math.min(maxLimit, Math.max(1, parseInt(query.limit || '20')))
  return { page, limit, skip: (page - 1) * limit }
}

export function paginationMeta(total: number, page: number, limit: number) {
  return { total, page, limit, totalPages: Math.ceil(total / limit) }
}
