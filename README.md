# TimIQ

TimIQ je osobní offline-first aplikace pro evidenci skutečně stráveného času.
Jedním klepnutím spustí aktivitu a klepnutím na jinou ji atomicky přepne.

## Architektura

- `lib/domain` – modely, výpočty statistik a timeline
- `lib/data` – verzovaná SQLite databáze a repository
- `lib/application` – jediný controller/use-case pro timer, CRUD a export
- `lib/presentation` – české obrazovky a vlastní TimIQ komponenty
- `lib/platform` – kanál pro synchronizaci s Androidem
- `android/app/src/main/kotlin/app/timiq` – widgety, notifikace a přímé
  transakční akce mimo Flutter UI

Databáze `timiq.db` používá cizí klíče, WAL, indexy pro časové dotazy a
částečný unikátní index, který dovolí nejvýše jeden záznam s `end_time IS NULL`.
Schéma se při upgradu nikdy automaticky nemaže.

## Lokální ověření

Po změně závislostí spusťte v kořeni projektu:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Pro instalaci widgetů použijte nabídku widgetů Android launcheru. Notifikační
oprávnění se na Androidu 13+ vyžádá při prvním spuštění měření.
