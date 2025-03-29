enum ProductCategory {
  clothing,art,jewelry,crafts,shop
}

 ProductCategory parseCategory(String category) {
  // Convert the string to a lowercase and then match it with enum values
  return ProductCategory.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == category.toLowerCase(),
    orElse: () => ProductCategory.clothing, // Return a default value if not found
  );
}