class ReservationService {
  // Map untuk menyimpan status booking: { "Nama_Item": "Status" }
  static Map<String, String> statuses = {
    "Sauna": "Available",
    "Swimming Pool": "Available",
    "VIP Table 1": "Available",
    "VIP Table 2": "Available",
    "VIP Table 3": "Available",
  };

  static void book(String title) {
    statuses[title] = "Booked";
  }
}