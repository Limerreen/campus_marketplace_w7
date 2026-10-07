import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryMock implements ItemRepository {
  @override
  Future<List<Item>> getItems() async {
    // จำลองโหลด 1 วินาที
    await Future.delayed(const Duration(seconds: 1));
    return const [
      Item(
        id: 1,
        title: 'หนังสือ Data Structures & Algorithms',
        price: 250.0,
        description: 'สภาพ 95% ไม่มีรอยขีดเขียน เหมาะสำหรับอ่านสอบ',
        category: 'หนังสือเรียน',
        imageUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=150',
      ),
      Item(
        id: 2,
        title: 'หูฟังไร้สาย Bluetooth 5.3',
        price: 490.0,
        description: 'แบตอึด ใช้งานได้ปกติ พร้อมกล่องชาร์จ',
        category: 'อุปกรณ์อิเล็กทรอนิกส์',
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=150',
      ),
      Item(
        id: 3,
        title: 'โคมไฟตั้งโต๊ะ LED Minimal',
        price: 180.0,
        description: 'ปรับระดับแสงได้ 3 โหมด ใช้งานในหอพัก',
        category: 'ของแต่งหอพัก',
        imageUrl:
            'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=150',
      ),
    ];
  }
}
