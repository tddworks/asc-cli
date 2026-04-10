/** Affordances map: action name → CLI command string, provided by the API */
export type Affordances = Record<string, string>;

/** Standard paginated API response */
export interface PaginatedResponse<T> {
  data: T[];
  links?: {
    next?: string;
    self?: string;
  };
}
