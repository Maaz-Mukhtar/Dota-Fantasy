import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../integrations/supabase/supabase.service';

// This service will be fully implemented in Slice 2
@Injectable()
export class TournamentsService {
  constructor(private supabase: SupabaseService) {}

  // Placeholder for tournament list
  async findAll() {
    // Will be implemented in Slice 2
    return {
      data: [],
      meta: {
        page: 1,
        limit: 20,
        total: 0,
      },
    };
  }

  // Placeholder for single tournament
  async findOne(id: string) {
    // Will be implemented in Slice 2
    return null;
  }
}
