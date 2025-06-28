// Helper method to extract filename from Supabase public URL
String? extractFileNameFromSupabaseUrl(String url) {
  try {
    Uri uri = Uri.parse(url);
    List<String> pathSegments = uri.pathSegments;

    // Find the index of 'public' and get the next segment after bucket name
    int publicIndex = pathSegments.indexOf('public');
    if (publicIndex != -1 && publicIndex + 2 < pathSegments.length) {
      // The filename should be after 'public/bucket-name/'
      return pathSegments[publicIndex + 2];
    }

    // Alternative: just get the last segment if the above doesn't work
    return pathSegments.last;
  } catch (e) {
    return null;
  }
}
