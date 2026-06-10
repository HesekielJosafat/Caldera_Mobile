class OrderService {
  // Map untuk menyimpan status pesanan: { "nama_menu": jumlah }
  static Map<String, int> activeOrders = {};

  static void addOrder(String name, int qty) {
    activeOrders[name] = qty;
  }

  static void removeOrder(String name) {
    activeOrders.remove(name);
  }

  static bool isOrdered(String name) {
    return activeOrders.containsKey(name);
  }
}