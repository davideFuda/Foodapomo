# Foodapomo

Foodapomo è un timer Pomodoro nativo per macOS, con interfaccia SwiftUI, storico persistente, attività personalizzabili, menu bar e integrazione Apple Calendar.

## Avvio

1. Installa Xcode 15 o successivo su macOS.
2. Clona il repository.
3. Apri `Package.swift` con Xcode.
4. Seleziona lo schema `Foodapomo` e avvia su **My Mac**.
5. Alla prima apertura consenti l'accesso al Calendario e alle notifiche.

Il progetto richiede macOS 14 Sonoma o successivo.

## Funzioni incluse

- timer con durata personalizzabile;
- pausa, ripresa e interruzione senza perdere i minuti effettivi;
- obiettivo giornaliero;
- descrizione dell'attività;
- storico persistente con sessioni dei giorni precedenti;
- grafico per fascia oraria;
- calendario Apple con selezione degli eventi;
- timer nella menu bar;
- notifiche locali.

La Dynamic Island non è disponibile su macOS: la versione Mac usa menu bar e notifiche come equivalente nativo. Una futura companion iPhone può aggiungere Live Activities e Dynamic Island.
