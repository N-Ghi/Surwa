enum Cartstatus {
  PENDING,PAID
}
 Cartstatus parseStatus(String status) {
  // Convert the string to a lowercase and then match it with enum values
  return Cartstatus.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == status.toLowerCase(),
    orElse: () => Cartstatus.PENDING, // Return a default value if not found
  );
 }