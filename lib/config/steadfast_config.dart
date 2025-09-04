class SteadFastConfig {
  // Read credentials from --dart-define at runtime. Do NOT hardcode secrets.
  static const String apiKey = String.fromEnvironment(
    'STEADFAST_API_KEY',
    defaultValue: '2lzhnd4lh28ec0qmfrzu5xt5ngzdqepp', // Default for development
  );
  
  static const String secretKey = String.fromEnvironment(
    'STEADFAST_SECRET_KEY', 
    defaultValue: '0aipppm44zd04bjvl5d8fu2t', // Default for development
  );

  // API Configuration
  static const String baseUrl = 'https://portal.packzy.com/api/v1';
  
  // API Endpoints
  static const String createOrderEndpoint = '/create_order';
  static const String bulkOrderEndpoint = '/create_order/bulk-order';
  static const String statusByCidEndpoint = '/status_by_cid';
  static const String statusByInvoiceEndpoint = '/status_by_invoice';
  static const String statusByTrackingEndpoint = '/status_by_trackingcode';
  static const String balanceEndpoint = '/get_balance';
  static const String createReturnEndpoint = '/create_return_request';

  // Request Headers
  static Map<String, String> get headers => {
        'Api-Key': apiKey,
        'Secret-Key': secretKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Delivery Types
  static const String pointDelivery = 'point_delivery';
  static const String homeDelivery = 'home_delivery';

  // Validation Constants
  static const int maxRecipientNameLength = 100;
  static const int maxAddressLength = 250;
  static const int phoneNumberLength = 11;
  static const int maxBulkOrders = 500;

  // Status Constants
  static const String statusPending = 'pending';
  static const String statusInTransit = 'in_transit';
  static const String statusDelivered = 'delivered';
  static const String statusReturned = 'returned';
  static const String statusCancelled = 'cancelled';
}