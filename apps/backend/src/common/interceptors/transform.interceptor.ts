import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface ApiResponse<T> {
  success: true;
  data: T;
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
  };
}

@Injectable()
export class TransformInterceptor<T>
  implements NestInterceptor<T, ApiResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        // If data is already in our format, return it as-is
        if (data && typeof data === 'object' && 'success' in data) {
          return data;
        }

        // Check if data contains pagination info
        if (data && typeof data === 'object' && 'data' in data && 'meta' in data) {
          return {
            success: true as const,
            data: data.data,
            meta: data.meta,
          };
        }

        // Wrap the data in our standard format
        return {
          success: true as const,
          data,
        };
      }),
    );
  }
}
