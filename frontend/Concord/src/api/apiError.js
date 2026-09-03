export class ApiError extends Error {
  constructor(message, status, options = {}) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.isNetworkError = Boolean(options.isNetworkError);
    this.isRateLimited = status === 429;
    if (options.cause !== undefined) {
      this.cause = options.cause;
    }
  }
}
