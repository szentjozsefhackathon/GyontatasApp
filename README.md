# Gyóntatás Alkalmazás

Flutter mobilalkalmazás templomi gyóntatások kezeléséhez. Az alkalmazás segítségével a templomi gondnokok egyszerűen jelezhetik a LoRaWAN rendszer felé a gyóntatás kezdetét és végét.

## Fő Funkciók

1. **Gyóntatás aktiválása**: Egyszerű felületen keresztül aktiválható a gyóntatás egy kiválasztott templomban.
2. **Automatikus jelzések**: Az alkalmazás 10 percenként automatikusan küld jelzést a LoRaWAN API-nak az aktív gyóntatás ideje alatt.
3. **Háttérben futás**: Az alkalmazás a háttérben is képes futni, ha van aktív gyóntatás.
4. **Kilépés megakadályozása**: A felhasználó nem tud kilépni az alkalmazásból, amíg a gyóntatás aktív.
5. **Felhasználói autentikáció**: Biztonságos bejelentkezés a templom gondnoki fiókjába.
6. **Értesítések**: Az alkalmazás értesítéseket küld az aktív gyóntatásról és az API frissítésekről.

## Technikai Megoldások

### Háttérszolgáltatás

Az alkalmazás két szintű háttér szolgáltatást implementál:

1. **EnhancedBackgroundService**: Flutter Background Service könyvtárat használja a háttérben futó szolgáltatáshoz, amely akkor is működik, amikor az alkalmazás nincs előtérben.

2. **NotificationService**: Értesítéseket küld a felhasználónak az alkalmazás állapotáról és a háttérben végrehajtott műveletekről.

### Alkalmazás Életciklus Kezelése

- **ServiceHandler**: Az alkalmazás életciklusát figyelő osztály, amely biztosítja, hogy a háttérszolgáltatás megfelelően működjön az alkalmazás különböző állapotaiban.

- **ExitDetector**: Speciális widget, amely megakadályozza az alkalmazásból való kilépést, ha aktív gyóntatás van folyamatban.

### Adattárolás és Szinkronizáció

- **SharedPreferences**: Az alkalmazás a helyi adattároláshoz SharedPreferences-t használ az aktív gyóntatás és a templom adatok tárolására.

- **ConfessionProvider**: Az aktív gyóntatás állapotát kezelő Provider osztály, amely értesíti a felhasználói felületet az állapotváltozásokról.

## Telepítés és Használat

1. Klónozza a repót:
```
git clone https://github.com/miserend/gyontatas_app.git
```

2. Telepítse a függőségeket:
```
flutter pub get
```

3. Futtassa az alkalmazást:
```
flutter run
```

## Platformspecifikus beállítások

### Android

- **Háttérszolgáltatás**: Az alkalmazás a háttérben futó szolgáltatásokat használ, amelyhez megfelelő jogosultságok és konfigurációk vannak beállítva.

### iOS

- **Háttér mód**: Az alkalmazás a háttérben is folyamatosan képes futni a beállított háttér módok segítségével.

## Fejlesztői Megjegyzések

- Az alkalmazás úgy van tervezve, hogy minimális akkumulátor használattal működjön, miközben megbízhatóan küldi a jelzéseket a LoRaWAN API felé.
- A 10 perces időzítő pontossága függ az operációs rendszer háttér optimalizálásaitól, különösen iOS rendszeren.
