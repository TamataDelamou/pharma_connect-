import '../../helpers/phone_layout.dart';
import 'c253_phone_width_overflow_test.dart' as phone_width;

// C268 : le même essai à 360 px, avec la police agrandie au maximum suivi par
// l'application (échelle 1,3, réglage « grande police » courant). Il échoue
// pour tout débordement, texte coupé à tort, mot coupé en deux et contraste
// sous les seuils, comme l'essai à l'échelle normale.
void main() {
  phoneTextScale = 1.3;
  phone_width.main();
}
