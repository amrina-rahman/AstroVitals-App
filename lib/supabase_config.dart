class SupabaseConfig {
  const SupabaseConfig._();

  static const projectUrl = 'https://niwutgldbybxkljadsac.supabase.co';
  static const publishableKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5pd3V0Z2xkYnlieGtsamFkc2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyNDQwMjksImV4cCI6MjEwOTgyMDAyOX0.gt8lUVPz1V5XeYiczLdmolZ_tUUguVhhWGs3-WYAOt8';

  static bool get isConfigured =>
      projectUrl.startsWith('https://') && publishableKey.trim().isNotEmpty;
}
