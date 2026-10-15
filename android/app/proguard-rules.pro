# Règles de réduction du code (R8) propres au projet.
#
# C248 : huit règles -dontwarn y figuraient pour les reconnaisseurs de texte
# chinois, devanagari, japonais et coréen de google_mlkit_text_recognition.
# C269 : cette bibliothèque est retirée de la version pilote ; les règles sont
# retirées avec elle. Le fichier reste déclaré dans build.gradle.kts pour les
# règles à venir.
