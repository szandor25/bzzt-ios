# BZZT! iOS

BZZT! to aplikacja iOS do wspolnej, online'owej gry quizowej. Gracze lacza sie w jednym pokoju przez 6-cyfrowy kod albo kod QR, odpowiadaja na pytania na swoich telefonach, a aplikacja synchronizuje lobby, rundy, wyniki, wyjasnienia i rewanz przez backend.

## Co aplikacja robi

- Tworzenie pokoju online i dolaczanie do istniejacej sesji.
- Dolaczanie przez reczne wpisanie kodu pokoju albo skan kodu QR.
- Lobby z lista graczy, gotowoscia i mozliwoscia startu, gdy wszyscy sa gotowi.
- Tryby gry:
  - **Party**: domyslny, flagowy tryb BZZT!, mieszajacy rozne formaty pytan i mechaniki wspolnej zabawy.
  - **Klasyczny**: spokojniejszy quiz z naciskiem na wiedze i uczciwa punktacje.
  - **Szybki**: krotsza, intensywna partia z mniejsza liczba rund.
- Pytania ABCD, prawda/falsz oraz rundy zalezne od danych wysylanych przez backend.
- Odtwarzanie plikow audio przypisanych do pytania oraz do wyjasnienia odpowiedzi.
- Plansza po odpowiedzi z poprawna odpowiedzia, wyjasnieniem, punktami i statusem gotowosci graczy.
- Przejscie do nastepnego pytania dopiero po zgodzie wszystkich graczy albo po limicie czasu.
- Ekran koncowy z rankingiem i opcja rewanzu w tej samej sesji.
- Ustawienia gracza, awatara, adresu backendu, dzwiekow i efektow.

## Wyglad i UX

Interfejs jest zbudowany w SwiftUI jako ciemna, energetyczna aplikacja imprezowa. Glowny motyw opiera sie na kontraście czerni, zolci i wyrazistych akcentow, z duzymi licznikami, czytelnymi kartami odpowiedzi i mocnym oznaczeniem aktualnego stanu gry. Ekrany sa podzielone na konkretne kroki: start, tworzenie/dolaczanie, lobby, runda, wyjasnienie, wyniki i rewanz.

Aplikacja ma przygotowana ikone zgodna z katalogiem `AppIcon.appiconset`, w wariancie podstawowym, ciemnym i tintowanym.

## Backend

Domyslny adres API:

```text
https://bzzt.e-aw.pl
```

Kod klienta backendu znajduje sie w:

- `BZZT!/BZZTBackendAPI.swift` - REST API i modele transportowe.
- `BZZT!/BZZTBackendWebSocket.swift` - polaczenie WebSocket i wysylanie akcji.
- `BZZT!/BZZTBackendMapping.swift` - mapowanie danych backendu na modele aplikacji.
- `BZZT!/BZZTGameStore.swift` - stan gry, audio, lobby, rundy i rematch.

Powiazany backend:

```text
https://github.com/szandor25/buzz-backend
```

## Wymagania

- Xcode z obsluga SwiftUI.
- iOS Simulator albo fizyczny iPhone.
- Dostep do internetu dla trybu online.
- Uprawnienie aparatu do skanowania kodow QR.

Przy testowaniu skanera QR w Xcode target aplikacji musi miec ustawiony wpis:

```text
NSCameraUsageDescription = Skanowanie kodu QR pokoju BZZT!
```

## Uruchomienie

1. Otworz projekt `BZZT!.xcodeproj` w Xcode.
2. Wybierz scheme `BZZT!`.
3. Uruchom aplikacje na symulatorze albo urzadzeniu.
4. Utworz pokoj albo dolacz do pokoju kodem/QR.

## Struktura

| Plik | Rola |
| --- | --- |
| `ContentView.swift` | Glowny router ekranow aplikacji. |
| `BZZTModels.swift` | Modele domenowe gry. |
| `BZZTGameStore.swift` | Centralny stan aplikacji i logika gry. |
| `BZZTLobbyViews.swift` | Ekrany tworzenia, dolaczania i lobby. |
| `BZZTRoundViews.swift` | Ekrany pytan i odpowiedzi. |
| `BZZTResultsViews.swift` | Wyniki rundy, wyjasnienia i podsumowanie. |
| `BZZTSettingsViews.swift` | Profil gracza i ustawienia. |
| `BZZTQRScannerView.swift` | Skaner kodow QR. |
| `BZZTDesignSystem.swift` | Kolory, style, tlo i wspolny wyglad. |

## Testy

Projekt zawiera testy jednostkowe dla logiki gry i mapowania backendu oraz testy UI startowego przeplywu aplikacji.
