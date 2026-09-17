ForeverChat 0.3.0-beta1 — Sanctum
by 0xgle

INSTALACJA (Classic Era / Hardcore, Interface 11509)
1. Zamknij WoW.
2. Zastąp folder ForeverChat w _classic_era_\Interface\AddOns\ folderem z ZIP-a.
   Plik ForeverChat.toc ma być bezpośrednio w AddOns\ForeverChat\.
3. Uruchom grę i włącz ForeverChat na liście dodatków.
4. /fc otwiera lub chowa okno. /fc settings otwiera ustawienia.
Nie usuwaj plików SavedVariables — historia i ustawienia są migrowane.
Jeśli okno jest poza ekranem, użyj /fc reset.

NOWA OPRAWA
Wygenerowany nagłówek, obsydianowe tło i osiem ikon w formacie TGA.
Złoto, turkus i ciemny kamień dopasowane do kolekcji Forever.
Wszystkie etykiety i przyciski są elementami interfejsu gry.
Motywy GOLD, AZERITE, TEAL, BLOOD zmieniają kolor akcentów; grafiki zachowują złoto/turkus.

OBSŁUGA
- Zakładki: wszystkie wiadomości, grupa, gildia, szepty, LFG, handel, alerty.
- Kółko myszy przewija historię. Shift+kółko: początek/koniec.
- Gdy czytasz historię, nowe wiadomości nie przesuwają widoku.
- BACK TO LIVE pokazuje najnowsze wiadomości i licznik oczekujących.
- COPY kopiuje bieżącą zakładkę z uwzględnieniem wyszukiwania: Ctrl+A, Ctrl+C.
- WRITE MESSAGE otwiera standardowy edytor czatu WoW.
- Kliknięcie wpisu w panelu szeptów lub LFG przygotowuje szept do tej osoby.
- HIDE SIDEBAR poszerza obszar wiadomości. LOCK blokuje przesuwanie okna.
- Przesuwaj okno za nagłówek. Skala dopasowuje się do dostępnego ekranu.
- Skróty można przypisać w ustawieniach klawiszy WoW > ForeverChat.
- Opcjonalny ForeverCore udostępnia otwieranie dodatku i jego ustawień.

KOMENDY
/fc                     pokaż/ukryj
/fc settings            ustawienia
/fc status              wersja i diagnostyka
/fc reset               przywróć położenie i rozmiar
/fc compact             przełącz panel boczny
/fc danger <opis>       ostrzeżenie do użytkowników ForeverChat w grupie/gildii
/fc block <słowo>        filtr tekstu
/fc unblock <słowo>      usuń filtr
/fc clear               usuń zapisaną historię czatu

ZAKRES I TESTY
Wersja do testów na Classic Era / Hardcore. Zgodność z klientem WoW Forever
wymaga osobnego sprawdzenia jego API. Nie deklarujemy wsparcia Retail.
13 testów logiki w symulowanym API WoW przeszło; sprawdzono również układ
na podglądzie z rzeczywistych definicji ramek. Nie uruchamiano klienta WoW.

LFG analizuje wyłącznie odebrane wiadomości, nie przeszukuje całego serwera.
Panel pokazuje ostatnie 15 minut, maksymalnie trzy różne osoby; parser używa
angielskich skrótów i nazw instancji. Ostrzeżenia nie zastępują oceny zagrożeń.
Historia: maksymalnie 500 wpisów w lokalnym SavedVariables.
Standardowy czat WoW pozostaje dostępny. Addon nie wysyła rozmów na stronę.
