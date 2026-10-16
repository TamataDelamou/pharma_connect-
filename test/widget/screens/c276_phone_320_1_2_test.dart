import '../../helpers/phone_layout.dart';
import 'c253_phone_width_overflow_test.dart' as phone_width;

// C276 : le même essai à 320 points, police à 1,2 (décision d'Achille du
// 16/10/2026 : 320 et 360 points × 1,0, 1,1, 1,15, 1,2 et 1,3, en mode
// strict). Il échoue pour tout débordement, texte coupé à tort, mot coupé en
// deux et contraste sous les seuils, comme l'essai à 360 points et 1,0.
void main() {
  phoneWidth = 320;
  phoneTextScale = 1.2;
  phone_width.main();
}
