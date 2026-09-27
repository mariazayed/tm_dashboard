import '../models/static_data.dart';
import 'static_data_service.dart';

class DataService {
  Future<StaticDataResponse> getAll() => StaticDataService.getAll();
}
