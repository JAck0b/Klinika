DROP USER IF EXISTS 'Klient'@'localhost';
CREATE USER 'Klient'@'localhost' IDENTIFIED BY '1234';
GRANT EXECUTE ON PROCEDURE klinika.wolne_miejsca TO 'Klient'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_zabieg TO 'Klient'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.usun_zabieg TO 'Klient'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.zaplata_za_zabieg TO 'Klient'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_klient_uslugi TO 'Klient'@'localhost';
FLUSH PRIVILEGES;

DROP USER IF EXISTS 'Pracownik'@'localhost';
CREATE USER 'Pracownik'@'localhost' IDENTIFIED BY '1234';
GRANT EXECUTE ON PROCEDURE klinika.wolne_miejsca TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_zabieg TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.usun_zabieg TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_nowego_klienta TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_klient_uslugi TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_nowe_stanowisko TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_uprawnienia_do_istniejacego_stanowiska TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_pracownik_dostep_do_stanowiska TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_pracownik_stanowiska TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_pracownik_uprawnienia TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.najczestszy_zabieg TO 'Pracownik'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.pracownik_miesiaca TO 'Pracownik'@'localhost';
FLUSH PRIVILEGES;

DROP USER IF EXISTS 'Prezes'@'localhost';
CREATE USER 'Prezes'@'localhost' IDENTIFIED BY '1234';
GRANT EXECUTE ON PROCEDURE klinika.dodaj_nowego_pracownika TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_prezes_stan_konta TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_prezes_transakcje TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_prezes_zabiegi TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_prezes_specjalizacje TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.dynamiczne_prezes_uzytkownicy TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.wyplac_pensje TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.wyplac_premie TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.zysk_w_ostatnich_dniach TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.najczestszy_zabieg TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.usun_pracownika TO 'Prezes'@'localhost';
GRANT EXECUTE ON PROCEDURE klinika.pracownik_miesiaca TO 'Prezes'@'localhost';

FLUSH PRIVILEGES;