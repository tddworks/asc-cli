/** Affordances map: action name → command or URL string */
export type Affordances = Record<string, string>;

/** Standard paginated API response */
export interface PaginatedResponse<T> {
  data: T[];
  links?: {
    next?: string;
    self?: string;
  };
}
