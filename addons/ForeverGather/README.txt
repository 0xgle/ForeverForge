FOREVER GATHERER — EXPEDITION
3.0.0 RC1 | by 0xgle

INSTALACJA (Classic Era)
1. Zamknij WoW.
2. Zrob kopie starego folderu Interface/AddOns/ForeverGather oraz danych
   WTF/Account/<konto>/SavedVariables/ForeverGather.lua.
3. Usun stary folder ForeverGather z AddOns i skopiuj ten nowy w jego miejsce.
   Nie usuwaj plikow z WTF. Folder i nazwa SavedVariables pozostaja takie same.
4. Prawidlowa sciezka: _classic_era_/Interface/AddOns/ForeverGather/ForeverGather.toc
   Nie umieszczaj calego ZIP-a ani dodatkowego folderu nadrzednego w AddOns.
5. Uruchom gre i wlacz Forever Gatherer na liscie dodatkow.
6. /fg otwiera Expedition. /fg hud wlacza lub wylacza maly HUD.

OBSLUGA
- Przeciagnij naglowek okna lub HUD-u, aby zmienic polozenie.
- Przycisk '-' zwija HUD; 'x' go ukrywa. Przywroc go przez /fg hud.
- Lewy przycisk ikony przy minimapie: Expedition. Prawy: HUD.
- Ikone przy minimapie mozna przeciagac dookola minimapy.
- Zbieraj normalnie: addon zapisuje poznane lokalizacje.
- Wybierz profesje / filtr nazwy i kliknij Build route.
- Lista Route stops przewija sie kolkiem myszy. Klikniecie wybiera aktywny punkt.
- Next stop pomija punkt. World map otwiera mape.
- TomTom waypoint wymaga osobno zainstalowanego TomTom; sam addon go nie wymaga.
- Resource atlas pokazuje zasoby i poznane strefy. Nie zawiera gotowej bazy lokacji.
- Settings zawiera ustawienia mapy, HUD-u, skali i reset polozenia okien.
- Import i Export all obsluguja poprzedni format FGX v2.
- New session archiwizuje biezaca sesje; nie kasuje poznanych punktow.

COMMANDS
/fg                Toggle Expedition window
/fg hud            Toggle compact HUD (also /fg bar)
/fg route          Build route from visible learned nodes
/fg route next     Advance to the next stop
/fg route clear    Clear active route
/fg focus <name>   Filter resource names
/fg focus clear    Clear resource and profession filters
/fg reset          Start a new session
/fg import         Open FGX import
/fg export         Export current map
/fg export all     Export the full local database
/fg diag           Diagnostics / Data Doctor

RELEASE STATUS
Target: WoW Classic Era, Interface 11509. This is a release candidate for
in-game testing, not a claim of completed in-game certification.
WoW Forever is the project context; its client/API compatibility is not verified.
No Forever-specific TOC or invented API compatibility is supplied.

Source baseline: available ForeverGather 2.7.0 BeautifulEdition. The screenshot
shows 2.8.0, but that source archive was not available for this rebuild.
The SavedVariables name ForeverGatherDB and schema 8 are retained. Nodes,
settings, analytics and session history use the existing database format.
No user data or test observations are bundled.

WHAT CHANGED
- Completely replaced HUD and primary UI layout code.
- Expedition, Resource atlas and Settings pages.
- Small draggable/collapsible HUD; persistent window positions.
- 15 new runtime textures, including generated scene, emblem, material and
  profession icons. No old giant ornamental panel textures are loaded.
- Bounded text fields, scrollable lists, screen-size fitting and clear spacing.
- Full route queue with selectable stops and active-stop scrolling.
- Route completion fix: the last stop is counted once, not on every update.
- Overlapping stop arrival latch; manual next-stop action.
- Small by 0xgle credit in the main window and HUD; Author metadata.
- Existing tracker, map provider, FGX data exchange and optional TomTom retained.

VALIDATION
Lua 5.1 syntax and mocked WoW widget/API tests passed; see TESTPLAN.txt.
Preview files show the layout constructed by the Lua code with a substitute
font. They are not screenshots from WoW. Native fonts, map interactions,
combat behavior and client event order still require in-game verification.

LICENSE
The existing project was MIT licensed. Its notice is retained, with attribution
to 0xgle for this revision. See LICENSE.txt and THIRD_PARTY.txt.
