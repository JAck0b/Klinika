-- Tutaj są kody wszystkich procedur
-- Tutaj są kody wszystkich procedur

# todo naprawić to, by się nie dało zapisać po godzinach pracy
# todo zamienić porównywanie dat na integery i staram się nie używać datatime (zamiast tego time)

# TODO można usunąć ilość i zostawić iterowanie po czasie
DROP PROCEDURE IF EXISTS wolne_miejsca;
DELIMITER //
CREATE PROCEDURE wolne_miejsca(IN data DATE, IN nazwa_uslugi VARCHAR(100), IN rodzaj_uslugi VARCHAR(50))
BEGIN
  DECLARE iterator_ogolny INT DEFAULT 0;
  DECLARE godzina_rozpoczecia TIME DEFAULT now();
  DECLARE godzina_zakonczenia TIME DEFAULT now();
  DECLARE iterator_godzin_wlasciwy TIME DEFAULT now();
  DECLARE iterator_godzin_int INT DEFAULT 0;
  DECLARE iterator_godzin_int_wewnetrzy INT DEFAULT 0;
  DECLARE ilosc_iteracji_godzin_wewnetrznych INT DEFAULT 0;
  DECLARE ilosc_iteracji_godzin INT DEFAULT 0;
  DECLARE iterator_zabiegow INT DEFAULT 0;
  DECLARE nowa_usluga_id INT DEFAULT 0;
  DECLARE nowe_uprawnienia_nazwa VARCHAR(45) DEFAULT '';
  DECLARE nowe_uprawnienia_grupa VARCHAR(45) DEFAULT '';
  DECLARE koniec_petli BOOLEAN DEFAULT FALSE;
  DECLARE znalezione_stanowisko INT DEFAULT 0;
  DECLARE maksymalna_ilosc_stanowiska INT DEFAULT 0;
  DECLARE obecna_ilosc_stanowiska INT DEFAULT 0;
  DECLARE nowa_usluga_czas_trwania INT DEFAULT 0;
  DECLARE imie_pracownika VARCHAR(30) DEFAULT '';
  DECLARE nazwisko_pracownika VARCHAR(30) DEFAULT '';
  DECLARE id_pracownika CHAR(11) DEFAULT '';
  DECLARE id_stanowiska INT DEFAULT 0;
  DECLARE ilosc_zabiegow INT DEFAULT -1;
  DECLARE ilosc_pasujacych_stanowisk INT DEFAULT -1;
  DECLARE ilosc_pasujacych_pracownikow INT DEFAULT -1;
  DECLARE pomocniczy_char CHAR(32);
  DECLARE znaleziono_stanowisko BOOLEAN DEFAULT TRUE;
  DECLARE znaleziono_pracownika BOOLEAN DEFAULT TRUE;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET koniec_petli = TRUE;

  # obliczanie skrajnych godzin pracy
  SELECT godziny_otwarcia.godzina_rozpoczecia
  FROM godziny_otwarcia
  WHERE godziny_otwarcia.ID = dayofweek(data)
  LIMIT 1
    INTO godzina_rozpoczecia;

  SELECT godziny_otwarcia.godzina_zakonczenia
  FROM godziny_otwarcia
  WHERE godziny_otwarcia.ID = dayofweek(data)
  LIMIT 1
    INTO godzina_zakonczenia;

  SET ilosc_iteracji_godzin = 32; # ustawienie na ile części jest dzielony dzień

  SET iterator_godzin_wlasciwy = godzina_rozpoczecia;

  # ustalanie jakie ma parametry nowa usługa

  SELECT uslugi_rehabilitacyjne.ID
  FROM uslugi_rehabilitacyjne
  WHERE uslugi_rehabilitacyjne.nazwa LIKE nazwa_uslugi
    AND uslugi_rehabilitacyjne.rodzaj LIKE rodzaj_uslugi
  LIMIT 1
    INTO nowa_usluga_id;

  SELECT uprawnienia.nazwa, uprawnienia.grupa
  FROM uprawnienia
         JOIN uslugi_rehabilitacyjne ON uprawnienia.nazwa = uslugi_rehabilitacyjne.uprawnienia
  WHERE uslugi_rehabilitacyjne.ID = nowa_usluga_id
  LIMIT 1
    INTO nowe_uprawnienia_nazwa, nowe_uprawnienia_grupa;

  SELECT uslugi_rehabilitacyjne.czas_trwania
  FROM uslugi_rehabilitacyjne
  WHERE uslugi_rehabilitacyjne.ID = nowa_usluga_id
  LIMIT 1
    INTO nowa_usluga_czas_trwania;

  # tutaj będą składowane wszystkie możliwe terminy zapisów
  DROP TABLE IF EXISTS mozliwe_terminy;
  CREATE TABLE mozliwe_terminy
  (
    imie       VARCHAR(30),
    nazwisko   VARCHAR(30),
    stanowisko INT,
    godzina    TIME
  );


  #   tutaj będą same dobre stanowiska
  DROP TABLE IF EXISTS stanowiska_pomoc;
  CREATE TABLE stanowiska_pomoc
  (
    ID             INT,
    max_ilosc_osob INT
  );
  INSERT INTO stanowiska_pomoc
  SELECT stanowiska.ID, stanowiska.max_ilosc_osob
  FROM stanowiska
         JOIN dostep_do_stanowiska ON stanowiska.ID = dostep_do_stanowiska.stanowisko
         JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.nazwa <= nowe_uprawnienia_nazwa
    AND uprawnienia.grupa = nowe_uprawnienia_grupa;


  DROP TABLE IF EXISTS pracownicy_pomoc;
  CREATE TABLE pracownicy_pomoc
  (
    PESEL    CHAR(11)
  );
  INSERT INTO pracownicy_pomoc (PESEL)
  SELECT DISTINCT uzytkownicy.PESEL
  FROM uzytkownicy
         JOIN specjalizacje ON uzytkownicy.PESEL = specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa >= nowe_uprawnienia_nazwa
    AND rola LIKE 'Pracownik';


  # biorę tylko te zabiegi z potrzebnymi stanowiskami, w danej godzinie na danym stanowisku jest tylko jeden 'rodzaj'
  # ćwiczeń, więc nie muszę przeglądać wszytskich zabiegów
  DROP TEMPORARY TABLE IF EXISTS odpowiednie_zabiegi;
  CREATE TEMPORARY TABLE odpowiednie_zabiegi #(stanowisko INT, pracownik CHAR(11), czas_zabiegu TIME, czas_trwania INT)
  SELECT DISTINCT zabiegi.stanowisko,
                  zabiegi.pracownik,
                  TIME(zabiegi.data_zabiegu) AS czas_zabiegu,
                  uslugi_rehabilitacyjne.czas_trwania
  FROM zabiegi
         JOIN uslugi_rehabilitacyjne ON zabiegi.usluga = uslugi_rehabilitacyjne.ID
         JOIN stanowiska_pomoc ON zabiegi.stanowisko = stanowiska_pomoc.ID
  WHERE DATE(zabiegi.data_zabiegu) LIKE data;


  DROP TABLE IF EXISTS zajete_stanowiska;
  CREATE TABLE zajete_stanowiska
  (
    stanowisko INT,
    czy_zajete CHAR(32)
  );

  # wylicznie siatki dla stanowisk//////////////////////////////////////////////////////
  # obliczam ile jest odpowiednich stanowisk, następnie przechodzę po wszystkich stanowiskach, które pasują
  # jednocześnie dla każdego ze stanowisk przelatuję po godzinach tak w zależności od tego, czy jest jakiś zabieg,
  # czy nie to uzupełniam tabelkę dostępności 0 lub 1
  SELECT count(stanowiska_pomoc.ID)
    FROM stanowiska_pomoc
    INTO ilosc_pasujacych_stanowisk;

  SET iterator_ogolny = 0;


  WHILE iterator_ogolny < ilosc_pasujacych_stanowisk DO
    SET iterator_godzin_int = 0;
    SET iterator_godzin_wlasciwy = godzina_rozpoczecia;

    SET pomocniczy_char = '';

    SELECT stanowiska_pomoc.ID
    FROM stanowiska_pomoc
    LIMIT iterator_ogolny, 1
    INTO id_stanowiska;

    WHILE iterator_godzin_int < ilosc_iteracji_godzin DO

      SET iterator_godzin_int_wewnetrzy = 0;
      SET ilosc_iteracji_godzin_wewnetrznych = -1;

      SELECT odpowiednie_zabiegi.czas_trwania
      FROM odpowiednie_zabiegi
      WHERE odpowiednie_zabiegi.stanowisko = id_stanowiska
        AND czas_zabiegu LIKE iterator_godzin_wlasciwy
#             LIMIT 1
        INTO ilosc_iteracji_godzin_wewnetrznych;

      IF ilosc_iteracji_godzin_wewnetrznych <> -1 THEN
        SET ilosc_iteracji_godzin_wewnetrznych = ilosc_iteracji_godzin_wewnetrznych/15;
        WHILE iterator_godzin_int_wewnetrzy < ilosc_iteracji_godzin_wewnetrznych DO

          SET pomocniczy_char = concat(pomocniczy_char, '1');
          SET iterator_godzin_int_wewnetrzy = iterator_godzin_int_wewnetrzy + 1;
          SET iterator_godzin_int = iterator_godzin_int + 1;
          SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
        END WHILE;

      ELSE
        SET pomocniczy_char = concat(pomocniczy_char, '0');
        SET iterator_godzin_int = iterator_godzin_int + 1;
        SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
      END IF ;

    END WHILE ;

    INSERT INTO zajete_stanowiska (stanowisko, czy_zajete)
    VALUES (id_stanowiska, pomocniczy_char);

    SET iterator_ogolny = iterator_ogolny + 1;
  END WHILE ;


    DROP TABLE IF EXISTS zajeci_pracownicy;
    CREATE TABLE zajeci_pracownicy
    (
      pracownik CHAR(11),
      czy_zajete CHAR(32)
    );


  # wyliczanie tej siatki dla pracowników //////////////////////////////////////////////////////
  # sposób wyliczania siatki jest analogiczny do wyliczania siatki stanowisk

  SELECT count(pracownicy_pomoc.PESEL)
    FROM pracownicy_pomoc
    INTO ilosc_pasujacych_pracownikow;

  SET iterator_ogolny = 0;

  WHILE iterator_ogolny < ilosc_pasujacych_pracownikow DO
    SET iterator_godzin_int = 0;
    SET iterator_godzin_wlasciwy = godzina_rozpoczecia;

    SET pomocniczy_char = '';

    SELECT pracownicy_pomoc.PESEL
    FROM pracownicy_pomoc
    LIMIT iterator_ogolny, 1
      INTO id_pracownika;

    WHILE iterator_godzin_int < ilosc_iteracji_godzin DO

      SET iterator_godzin_int_wewnetrzy = 0;
      SET ilosc_iteracji_godzin_wewnetrznych = -1;

      SELECT odpowiednie_zabiegi.czas_trwania
      FROM odpowiednie_zabiegi
      WHERE odpowiednie_zabiegi.pracownik = id_pracownika
        AND odpowiednie_zabiegi.czas_zabiegu = iterator_godzin_wlasciwy
#             LIMIT 1
            INTO ilosc_iteracji_godzin_wewnetrznych;

      IF ilosc_iteracji_godzin_wewnetrznych <> -1 THEN
        SET ilosc_iteracji_godzin_wewnetrznych = ilosc_iteracji_godzin_wewnetrznych/15;
        WHILE iterator_godzin_int_wewnetrzy < ilosc_iteracji_godzin_wewnetrznych DO

          SET pomocniczy_char = concat(pomocniczy_char, '1');
          SET iterator_godzin_int_wewnetrzy = iterator_godzin_int_wewnetrzy + 1;
          SET iterator_godzin_int = iterator_godzin_int + 1;
          SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
        END WHILE ;

      ELSE
        SET pomocniczy_char = concat(pomocniczy_char, '0');
        SET iterator_godzin_int = iterator_godzin_int + 1;
        SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
      END IF ;

    END WHILE ;

    INSERT INTO zajeci_pracownicy (pracownik, czy_zajete)
    VALUES (id_pracownika, pomocniczy_char);

    SET iterator_ogolny = iterator_ogolny + 1;
  END WHILE ;

  # ulepszona tabela z zabiegami, która sprawdza, czy dany pracownik, może wykonać zabieg, czy sala jest dobra
  # oraz czy jest odpowiednio długo sala wypożyczona

  DROP TABLE IF EXISTS zabiegi_pomoc;
  CREATE TABLE zabiegi_pomoc
  (
    pracownik         VARCHAR(45),
    czas_zabiegu      TIME,
    czas_trwania      INT,
    stanowisko        INT,
    ilosc_klientow    INT,
    max_liczba_miejsc INT,
    imie_pracownika VARCHAR(30),
    nazwisko_pracownika VARCHAR(30)
  );
  INSERT INTO zabiegi_pomoc
  SELECT DISTINCT zabiegi.pracownik,
                  time(zabiegi.data_zabiegu),
                  uslugi_rehabilitacyjne.czas_trwania,
                  zabiegi.stanowisko,
                  count(zabiegi.ID),
                  stanowiska.max_ilosc_osob,
                  uzytkownicy.imie,
                  uzytkownicy.nazwisko
  FROM zabiegi
         JOIN uzytkownicy ON zabiegi.pracownik = uzytkownicy.PESEL
         JOIN specjalizacje ON uzytkownicy.PESEL = specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
         JOIN uslugi_rehabilitacyjne ON zabiegi.usluga = uslugi_rehabilitacyjne.ID
         JOIN stanowiska ON zabiegi.stanowisko = stanowiska.ID
  WHERE uprawnienia.grupa LIKE nowe_uprawnienia_grupa
    AND uprawnienia.nazwa >= nowe_uprawnienia_grupa # wystarczy sprawdzić pracownika, bo ma tylko jedną specjalizację
    AND DATE(zabiegi.data_zabiegu) LIKE data
    AND uslugi_rehabilitacyjne.czas_trwania = nowa_usluga_czas_trwania
  GROUP BY zabiegi.pracownik, time(zabiegi.data_zabiegu), uslugi_rehabilitacyjne.czas_trwania, zabiegi.stanowisko,
           stanowiska.max_ilosc_osob;



  ############################################################################################################
  # w tym miesjcu zaczyna się głowna część procedury, przchodze tutaj po wszystkich godzinach i dla każdej z godzin
  # sprawdzam, czy nie ma jakiegoś zabiegu, jeżeli jest to próbuję połączyć nowy zabieg z istniejącymi,
  # w przeciwnym przypadku, jezeli nie znajduję żadnych pasuących zabiegów do połączenia, to szukam własnego
  # na podstawie tych siatek dostępności

  SET iterator_godzin_int = 0;
  SET iterator_godzin_wlasciwy = godzina_rozpoczecia;
  petla_godzin: WHILE iterator_godzin_int < ilosc_iteracji_godzin DO
  SET iterator_zabiegow = 0;
  SET koniec_petli = FALSE;
  SELECT count(*)
  FROM zabiegi_pomoc
  WHERE czas_zabiegu LIKE iterator_godzin_wlasciwy
  INTO ilosc_zabiegow;
  petla_zabiegi: WHILE iterator_zabiegow < ilosc_zabiegow AND koniec_petli = FALSE DO

  SELECT zabiegi_pomoc.imie_pracownika,
         zabiegi_pomoc.nazwisko_pracownika,
         zabiegi_pomoc.max_liczba_miejsc,
         zabiegi_pomoc.ilosc_klientow,
         zabiegi_pomoc.stanowisko
  FROM zabiegi_pomoc
  WHERE czas_zabiegu LIKE iterator_godzin_wlasciwy
  LIMIT iterator_zabiegow, 1
    INTO imie_pracownika, nazwisko_pracownika, maksymalna_ilosc_stanowiska, obecna_ilosc_stanowiska, znalezione_stanowisko;

  #     musi byś miejsce na stanowisku, salka musi móc przymowac taki zbieg,
  #     pracownik musi mieć minimalne uprawnienia oraz czas musi być ten sam
  IF maksymalna_ilosc_stanowiska - 1 >= obecna_ilosc_stanowiska AND
     koniec_petli = FALSE THEN
    INSERT INTO mozliwe_terminy (imie, nazwisko, stanowisko, godzina)
    VALUES (imie_pracownika, nazwisko_pracownika, znalezione_stanowisko, iterator_godzin_wlasciwy);

    SET koniec_petli = TRUE;

  END IF ;

  SET iterator_zabiegow = iterator_zabiegow + 1;
  END WHILE ;
  # jeżeli nie się do czego podłączyć
    IF koniec_petli = FALSE THEN
       SET iterator_ogolny = 0;
      SET znaleziono_stanowisko = FALSE;
      SET pomocniczy_char = '';

      # szukanie stanowiska
      WHILE iterator_ogolny < ilosc_pasujacych_stanowisk AND znaleziono_stanowisko = FALSE DO

        SELECT zajete_stanowiska.stanowisko, zajete_stanowiska.czy_zajete
        FROM zajete_stanowiska
        LIMIT iterator_ogolny, 1
        INTO id_stanowiska, pomocniczy_char;

        SET iterator_godzin_int_wewnetrzy = iterator_godzin_int + 1;
        SET ilosc_iteracji_godzin_wewnetrznych = nowa_usluga_czas_trwania/15 + iterator_godzin_int + 1;
        set znaleziono_stanowisko = TRUE;

        WHILE iterator_godzin_int_wewnetrzy < ilosc_iteracji_godzin_wewnetrznych AND iterator_godzin_int_wewnetrzy <= 32
          AND znaleziono_stanowisko = TRUE DO

          IF substring(pomocniczy_char, iterator_godzin_int_wewnetrzy, 1) = '1' THEN
            SET znaleziono_stanowisko = FALSE;
          END IF ;


          SET iterator_godzin_int_wewnetrzy = iterator_godzin_int_wewnetrzy + 1;
          IF iterator_godzin_int_wewnetrzy = 33 THEN
            SET znaleziono_stanowisko = FALSE;
          END IF ;
        END WHILE ;

        SET iterator_ogolny = iterator_ogolny + 1;
      END WHILE ;

      # szuka tylko wtedy, gdy jest sens, bo jest stanowisko
      IF znaleziono_stanowisko = TRUE THEN


        SET iterator_ogolny = 0;
        SET znaleziono_pracownika = FALSE;
        SET pomocniczy_char = '';
        # szukanie pracownika
        WHILE iterator_ogolny < ilosc_pasujacych_pracownikow AND znaleziono_pracownika = FALSE DO
          SELECT zajeci_pracownicy.pracownik, zajeci_pracownicy.czy_zajete
          FROM zajeci_pracownicy
          LIMIT iterator_ogolny, 1
            INTO id_pracownika, pomocniczy_char;

          SET iterator_godzin_int_wewnetrzy = iterator_godzin_int + 1;
          SET ilosc_iteracji_godzin_wewnetrznych = nowa_usluga_czas_trwania / 15 + iterator_godzin_int + 1;
          SET znaleziono_pracownika = TRUE;

          WHILE iterator_godzin_int_wewnetrzy < ilosc_iteracji_godzin_wewnetrznych AND iterator_godzin_int_wewnetrzy <= 32
            AND znaleziono_pracownika = TRUE DO
            IF substring(pomocniczy_char, iterator_godzin_int_wewnetrzy, 1) = '1' THEN
              SET znaleziono_pracownika = FALSE;
            END IF ;


            SET iterator_godzin_int_wewnetrzy = iterator_godzin_int_wewnetrzy + 1;
            IF iterator_godzin_int_wewnetrzy = 33 THEN
              SET znaleziono_pracownika = FALSE;
            END IF ;
          END WHILE ;

          SET iterator_ogolny = iterator_ogolny + 1;
        END WHILE;
        # jeżeli jest pracownik i stanowisko to wrzuca kombinacje do tabeli z możliwymi zabiegami
        IF znaleziono_pracownika = TRUE THEN

          SELECT uzytkownicy.imie, uzytkownicy.nazwisko
          FROM uzytkownicy
          WHERE uzytkownicy.PESEL = id_pracownika INTO imie_pracownika, nazwisko_pracownika;

          INSERT INTO mozliwe_terminy (imie, nazwisko, stanowisko, godzina)
          VALUES (imie_pracownika, nazwisko_pracownika, id_stanowiska, iterator_godzin_wlasciwy);

        END IF ;

      END IF;
    END IF ;
  SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
  SET iterator_godzin_int = iterator_godzin_int + 1;
  END WHILE;

  SELECT *
  FROM mozliwe_terminy;


  DROP TABLE IF EXISTS stanowiska_pomoc;
  DROP TABLE IF EXISTS pracownicy_pomoc;
  DROP TABLE IF EXISTS zabiegi_pomoc;
  DROP TABLE IF EXISTS mozliwe_terminy;
  DROP TEMPORARY TABLE IF EXISTS odpowiednie_zabiegi;
  DROP TABLE IF EXISTS zajeci_pracownicy;
  DROP TABLE IF EXISTS zajete_stanowiska;
END //
DELIMITER ;

CALL wolne_miejsca('2019-01-17', 'Argonowy', 'Laseroterapia');
////////////////////////////////////////////////

DROP PROCEDURE IF EXISTS doladowanie_konta;
DELIMITER //
CREATE PROCEDURE doladowanie_konta(IN PESEL CHAR(11), IN kwota INT)
BEGIN
  UPDATE stan_konta SET saldo = saldo + kwota WHERE uzytkownik = PESEL;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS zysk_w_ostatnich_dniach;
DELIMITER //
CREATE PROCEDURE zysk_w_ostatnich_dniach(IN data_poczatku DATE, IN data_konca date)
BEGIN
  DECLARE zysk INT DEFAULT 0;
  DECLARE pesel_menagera CHAR(11);
  DECLARE i INT DEFAULT 0; #iterator
  DECLARE przychod INT DEFAULT 0;
  DECLARE wydatki INT DEFAULT 0;
  DECLARE ilosc_dni INT DEFAULT 0;

  SET ilosc_dni = datediff(data_konca, data_poczatku);
  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes' INTO pesel_menagera;

  WHILE i <= ilosc_dni DO
  SELECT sum(kwota)
  FROM transakcje
  WHERE odbiorca = pesel_menagera
    AND data = date_sub(data_konca, INTERVAL i DAY) INTO przychod;

  SELECT sum(kwota)
  FROM transakcje
  WHERE placacy = pesel_menagera
    AND data = date_sub(data_konca, INTERVAL i DAY) INTO wydatki;

  IF NOT ISNULL(przychod) THEN #w danzm dniu moe nie bz transkacji wtedy null wsyztkow psuje
    SET zysk = zysk + przychod;
  END IF;
  IF NOT ISNULL(wydatki) THEN #w danzm dniu moe nie bz transkacji wtedy null wsyztkow psuje
    SET zysk = zysk - wydatki;
  END IF;

  SET i = i + 1;
  END WHILE;
  SELECT zysk;
END//
DELIMITER ;


DROP PROCEDURE IF EXISTS wyplac_pensje;
DELIMITER //
CREATE PROCEDURE wyplac_pensje()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE liczba_pracownikow INT DEFAULT 0;
  DECLARE pensja_pracownika INT DEFAULT 0;
  DECLARE budzet INT;
  DECLARE pesel_menagera CHAR(11);
  DECLARE pesel_pracownika CHAR(11);
  SET liczba_pracownikow = (SELECT count(pracownik) FROM specjalizacje);

  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes' INTO pesel_menagera;

  SELECT saldo
  FROM stan_konta
  WHERE uzytkownik = pesel_menagera INTO budzet;

  SET autocommit = 0;
  START TRANSACTION
    ;
    DROP TEMPORARY TABLE IF EXISTS T;
    CREATE TEMPORARY TABLE T AS
    SELECT pensja, pracownik FROM specjalizacje;
    WHILE i < liczba_pracownikow DO
    SET pensja_pracownika = (SELECT pensja FROM T LIMIT i,1);
    SET pesel_pracownika = (SELECT pracownik FROM T LIMIT i,1);
    SET budzet = budzet - pensja_pracownika;
    CALL doladowanie_konta(pesel_menagera, - pensja_pracownika);
    INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
    VALUES (pesel_pracownika, pesel_menagera, current_date(), pensja_pracownika, 'pensja');
    SET i = i + 1;
    END WHILE;

    IF (budzet >= 0) THEN
      COMMIT;
      SELECT "Wyplaty zakonczone";
    ELSE
      ROLLBACK;
      SELECT "Brak srodkow!";
    END IF;
    DROP TEMPORARY TABLE T
  ;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS wyplac_premie;
DELIMITER //
CREATE PROCEDURE wyplac_premie(IN liczba_pracownikow INT, IN kwota_premi INT)
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE budzet INT;
  DECLARE pesel_menagera CHAR(11);
  DECLARE pesel_pracownika CHAR(11);

  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes' INTO pesel_menagera;

  SELECT saldo
  FROM stan_konta
  WHERE uzytkownik = pesel_menagera INTO budzet;

  SET autocommit = 0;
  START TRANSACTION
    ;
    DROP TEMPORARY TABLE IF EXISTS T;

    #znajduje pracownika ktorzy wykoanli najwiecej zabiegow w tym miesiacu
    # (w tabeli zabiegi jak zabieg jest dla większej liczby osboób występuje kilka kronie)
    CREATE TEMPORARY TABLE T
    AS
    SELECT x.pracownik, count(x.data_zabiegu) AS pom
    FROM (SELECT DISTINCT pracownik, data_zabiegu FROM zabiegi WHERE month(data_zabiegu) = month(current_date())) AS x
    GROUP BY x.pracownik
    ORDER BY pom DESC
    LIMIT liczba_pracownikow;

    WHILE i < liczba_pracownikow DO
    SET pesel_pracownika = (SELECT pracownik FROM T LIMIT i,1);
    SET budzet = budzet - kwota_premi;
    CALL doladowanie_konta(pesel_menagera, - kwota_premi);
    INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
    VALUES (pesel_pracownika, pesel_menagera, current_date(), kwota_premi, 'premia');
    SET i = i + 1;
    END WHILE;

    IF (budzet >= 0) THEN
      COMMIT;
      SELECT "Wyplaty zakonczone";
    ELSE
      ROLLBACK;
      SELECT "Brak srodkow!";
    END IF;
    DROP TEMPORARY TABLE T
  ;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS pracownik_miesiaca;
DELIMITER //
CREATE PROCEDURE pracownik_miesiaca()
BEGIN
  SELECT x.pracownik AS pracownik_miesiaca
  FROM (SELECT DISTINCT pracownik, data_zabiegu FROM zabiegi WHERE month(data_zabiegu) = month(current_date())) AS x
  GROUP BY x.pracownik
  ORDER BY count(data_zabiegu) DESC
  LIMIT 1;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS najczestszy_zabieg;
DELIMITER //
CREATE PROCEDURE najczestszy_zabieg()
BEGIN
  SELECT nazwa AS najczestszy_zabieg
  FROM (SELECT DISTINCT usluga, data_zabiegu FROM zabiegi) AS x
         JOIN uslugi_rehabilitacyjne ON x.usluga = uslugi_rehabilitacyjne.ID
  GROUP BY x.usluga
  ORDER BY count(data_zabiegu) DESC
  LIMIT 1;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS zaplata_za_zabieg;
DELIMITER //
CREATE PROCEDURE zaplata_za_zabieg(IN pesel_klienta CHAR(11), IN id_zabiegu INT)
BEGIN
  DECLARE stan_konta_klienta INT;
  DECLARE pesel_menagera CHAR(11);
  DECLARE rodzaj_uslugi INT;
  DECLARE cena_zabiegu INT;
  DECLARE stan ENUM ('tak','nie');

  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes' INTO pesel_menagera;

  SELECT usluga,oplacono
  FROM zabiegi
  WHERE ID = id_zabiegu
    AND klient = pesel_klienta INTO rodzaj_uslugi, stan;

  SELECT saldo
  FROM stan_konta
  WHERE uzytkownik = pesel_klienta INTO stan_konta_klienta;

  SELECT cena
  FROM uslugi_rehabilitacyjne
  WHERE ID = rodzaj_uslugi INTO cena_zabiegu;

  IF (stan = 'nie') THEN
    SET autocommit = 0;
    START TRANSACTION
      ;

      SET stan_konta_klienta = stan_konta_klienta - cena_zabiegu;
      CALL doladowanie_konta(pesel_menagera, cena_zabiegu);
      CALL doladowanie_konta(pesel_klienta, -cena_zabiegu);
      INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
      VALUES (pesel_menagera, pesel_klienta, current_date(), cena_zabiegu, 'za_zabieg');
      UPDATE zabiegi SET oplacono = 'tak' WHERE ID = id_zabiegu;

      IF (stan_konta_klienta >= 0) THEN
        SELECT "Zaplacono";
        COMMIT;
      ELSE
        ROLLBACK;
        SELECT "Brak srodkow!";
      END IF
    ;
  ELSE
    SELECT "Juz oplacono";
  END IF;


END//
DELIMITER ;

DROP PROCEDURE IF EXISTS dodaj_nowe_stanowisko;
DELIMITER //
CREATE PROCEDURE dodaj_nowe_stanowisko(IN nazwa_stanowiska VARCHAR(45), IN max_liczba_osob_na_stanowisku INT,
                                       wymagane_uprawnienia_na_dane_stanowisko VARCHAR(45))
BEGIN
  DECLARE ilosc_stanowik INT;

  SELECT count(ID)
  FROM stanowiska INTO ilosc_stanowik;

  IF wymagane_uprawnienia_na_dane_stanowisko IN (SELECT nazwa FROM uprawnienia) THEN
    INSERT INTO stanowiska (ID, nazwa, max_ilosc_osob)
    VALUES (ilosc_stanowik + 1, nazwa_stanowiska, max_liczba_osob_na_stanowisku);

    INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia)
    VALUES (ilosc_stanowik + 1, wymagane_uprawnienia_na_dane_stanowisko);

    SELECT "Dodano";
  ELSE
    SELECT "Bledne uprawnienia";

  END IF;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS dodaj_uprawnienia_do_istniejacego_stanowiska;
DELIMITER //
CREATE PROCEDURE dodaj_uprawnienia_do_istniejacego_stanowiska(IN ID_stanowiska INT,
                                                              wymagane_uprawnienia_na_dane_stanowisko VARCHAR(45))
BEGIN

  IF wymagane_uprawnienia_na_dane_stanowisko IN (SELECT nazwa FROM uprawnienia) AND
     ID_stanowiska IN (SELECT stanowisko FROM dostep_do_stanowiska) THEN

    INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia)
    VALUES (ID_stanowiska, wymagane_uprawnienia_na_dane_stanowisko);

    SELECT "Dodano";
  ELSE
    SELECT "Bledne uprawnienia lub stanowisko";

  END IF;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS dodaj_nowego_pracownika;
DELIMITER //
CREATE PROCEDURE dodaj_nowego_pracownika(IN pesel_pracownika CHAR(11), IN imie_pracownika VARCHAR(30),
                                         IN nazwisko_pracownika VARCHAR(30), uprawnienia_pracownika VARCHAR(45),
                                         IN pensja_pracownika INT)
BEGIN

  IF uprawnienia_pracownika IN (SELECT nazwa FROM uprawnienia) THEN

    INSERT INTO uzytkownicy (PESEL, imie, nazwisko, data_dolaczenia, rola)
    VALUES (pesel_pracownika, imie_pracownika, nazwisko_pracownika, current_date(), 'pracownik');

    INSERT INTO specjalizacje (pracownik, uprawnienia, pensja)
    VALUES (pesel_pracownika, uprawnienia_pracownika, pensja_pracownika);

    SELECT "Dodano";
  ELSE
    SELECT "Bledne uprawnienia";

  END IF;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS dodaj_nowego_klienta;
DELIMITER //
CREATE PROCEDURE dodaj_nowego_klienta(IN pesel_klienta CHAR(11), IN imie_klienta VARCHAR(30),
                                      IN nazwisko_klienta VARCHAR(30), IN kwota_na_koncie_klienta INT)
BEGIN

  INSERT INTO uzytkownicy (PESEL, imie, nazwisko, data_dolaczenia, rola)
  VALUES (pesel_klienta, imie_klienta, nazwisko_klienta, current_date(), 'klient');

  INSERT INTO stan_konta (uzytkownik, saldo)
  VALUES (pesel_klienta, kwota_na_koncie_klienta);

  SELECT "Dodano";

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS usun_zabieg;
DELIMITER //
CREATE PROCEDURE usun_zabieg(IN id_zabiegu INT)
BEGIN
  DECLARE pesel_menagera CHAR(11);
  DECLARE pesel_klienta CHAR(11);
  DECLARE saldo_kliniki INT;
  DECLARE rodzaj_uslugi INT;
  DECLARE cena_zabiegu INT;
  DECLARE stan ENUM ('tak','nie');

  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes' INTO pesel_menagera;

  IF id_zabiegu IN (SELECT ID FROM zabiegi) THEN
    SELECT usluga,oplacono,klient
    FROM zabiegi
    WHERE ID = id_zabiegu INTO rodzaj_uslugi, stan,pesel_klienta;

    IF stan = 'tak' THEN
      SELECT saldo
      FROM stan_konta
      WHERE uzytkownik = pesel_menagera INTO saldo_kliniki;

      SELECT cena
      FROM uslugi_rehabilitacyjne
      WHERE ID = rodzaj_uslugi INTO cena_zabiegu;

      SET autocommit = 0;
      START TRANSACTION
        ;

        SET saldo_kliniki = saldo_kliniki - cena_zabiegu;
        CALL doladowanie_konta(pesel_menagera, -cena_zabiegu);
        CALL doladowanie_konta(pesel_klienta, cena_zabiegu);
        INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
        VALUES (pesel_klienta, pesel_menagera, current_date(), cena_zabiegu, 'zwrot');

        IF (saldo_kliniki >= 0) THEN
          COMMIT;
          DELETE FROM zabiegi WHERE ID = id_zabiegu;
          SELECT "Usunieto";
        ELSE
          ROLLBACK;
          SELECT "Brak srodkow";
        END IF
      ;

    ELSE
      DELETE FROM zabiegi WHERE ID = id_zabiegu;
      SELECT "Usunieto";
    END IF;
  ELSE
    SELECT "Brak zabiegu";
  END IF;


END//
DELIMITER ;

DROP PROCEDURE IF EXISTS usun_klienta; #usuwa przyszłe zabiegi jesli były opcoce robi zwrot; likwiduje stan konta klienta; pesel zostaje w bazie dla historycznych zabigow i transakcji
DELIMITER //
CREATE PROCEDURE usun_klienta(IN pesel_klienta char(11))
BEGIN
  DECLARE pesel_menagera CHAR(11);
  DECLARE i INT DEFAULT 0;
  DECLARE liczba_zabiegow INT;
  DECLARE saldo_kliniki INT;
  DECLARE rodzaj_uslugi INT;
  DECLARE cena_zabiegu INT;
  DECLARE id_zabiegu INT;
  DECLARE mozliwe INT DEFAULT 1;
  DECLARE stan ENUM ('tak','nie');

  IF pesel_klienta IN (SELECT uzytkownik FROM stan_konta) THEN

    SELECT PESEL
    FROM uzytkownicy
    WHERE rola LIKE 'Prezes' INTO pesel_menagera;

    DROP TEMPORARY TABLE IF EXISTS T;
    CREATE TEMPORARY TABLE T AS
    SELECT ID FROM zabiegi WHERE klient = pesel_klienta AND data_zabiegu >= current_date();

    SELECT count(ID)
    FROM T INTO liczba_zabiegow;

    SET autocommit = 0;
    START TRANSACTION
      ;

      w: WHILE i < liczba_zabiegow DO
      SET id_zabiegu = (SELECT ID FROM T LIMIT i,1);
      SELECT usluga,oplacono
      FROM zabiegi
      WHERE ID = id_zabiegu INTO rodzaj_uslugi, stan;

      IF stan = 'tak' THEN
        SELECT saldo
        FROM stan_konta
        WHERE uzytkownik = pesel_menagera INTO saldo_kliniki;

        SELECT cena
        FROM uslugi_rehabilitacyjne
        WHERE ID = rodzaj_uslugi INTO cena_zabiegu;

        SET saldo_kliniki = saldo_kliniki - cena_zabiegu;
        CALL doladowanie_konta(pesel_menagera, -cena_zabiegu);
        CALL doladowanie_konta(pesel_klienta, cena_zabiegu);
        INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
        VALUES (pesel_klienta, pesel_menagera, current_date(), cena_zabiegu, 'zwrot');

        IF (saldo_kliniki >= 0) THEN
          DELETE FROM zabiegi WHERE ID = id_zabiegu;
        ELSE
          SET mozliwe = 0;
          LEAVE w;
        END IF;
      ELSE
        DELETE FROM zabiegi WHERE ID = id_zabiegu;
      END IF;
      SET i = i + 1;
      END WHILE;

      IF mozliwe = 1 THEN
        DELETE FROM stan_konta WHERE uzytkownik = pesel_klienta;
        COMMIT;
        SELECT "Usunieto";
      ELSE
        ROLLBACK;
        SELECT "Brak srodkow";
      END IF;
      DROP TEMPORARY TABLE IF EXISTS T
    ;

  ELSE
    SELECT "Bledny pesel";
  END IF;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS usun_pracownika; #usuwa przyszłe zabiegi jesli były opcoce robi zwrot ; likwiduje pozycje w specjalizach ; pesel zostaje w bazie dla historycznych zabigow i transakcji
DELIMITER //
CREATE PROCEDURE usun_pracownika(IN pesel_pracownika char(11))
BEGIN
  DECLARE pesel_menagera CHAR(11);
  DECLARE pesel_klienta CHAR(11);
  DECLARE i INT DEFAULT 0;
  DECLARE liczba_zabiegow INT;
  DECLARE saldo_kliniki INT;
  DECLARE rodzaj_uslugi INT;
  DECLARE cena_zabiegu INT;
  DECLARE id_zabiegu INT;
  DECLARE mozliwe INT DEFAULT 1;
  DECLARE stan ENUM ('tak','nie');

  IF pesel_pracownika IN (SELECT pracownik FROM specjalizacje) THEN

    SELECT PESEL
    FROM uzytkownicy
    WHERE rola LIKE 'Prezes' INTO pesel_menagera;

    DROP TEMPORARY TABLE IF EXISTS T;
    CREATE TEMPORARY TABLE T AS
    SELECT ID,klient,data_zabiegu FROM zabiegi WHERE pracownik = pesel_pracownika AND data_zabiegu >= current_date();

    SELECT count(ID)
    FROM T INTO liczba_zabiegow;

    SET autocommit = 0;
    START TRANSACTION
      ;
      w: WHILE i < liczba_zabiegow DO
      SET id_zabiegu = (SELECT ID FROM T LIMIT i,1);
      SELECT usluga,oplacono,klient
      FROM zabiegi
      WHERE ID = id_zabiegu INTO rodzaj_uslugi, stan,pesel_klienta;

      IF stan = 'tak' THEN
        SELECT saldo
        FROM stan_konta
        WHERE uzytkownik = pesel_menagera INTO saldo_kliniki;

        SELECT cena
        FROM uslugi_rehabilitacyjne
        WHERE ID = rodzaj_uslugi INTO cena_zabiegu;

        SET saldo_kliniki = saldo_kliniki - cena_zabiegu;
        CALL doladowanie_konta(pesel_menagera, -cena_zabiegu);
        CALL doladowanie_konta(pesel_klienta, cena_zabiegu);
        INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
        VALUES (pesel_klienta, pesel_menagera, current_date(), cena_zabiegu, 'zwrot');

        IF (saldo_kliniki >= 0) THEN
          DELETE FROM zabiegi WHERE ID = id_zabiegu;
        ELSE
          SET mozliwe = 0;
          LEAVE w;
        END IF;
      ELSE
        DELETE FROM zabiegi WHERE ID = id_zabiegu;
      END IF;
      SET i = i + 1;
      END WHILE;

      IF mozliwe = 1 THEN
        DELETE FROM specjalizacje WHERE pracownik = pesel_pracownika;
        COMMIT;
        SELECT "Usunieto";
        SELECT * FROM T AS odwolane_zabiegi;
      ELSE
        ROLLBACK;
        SELECT "Brak srodkow";
      END IF;
      DROP TEMPORARY TABLE IF EXISTS T
    ;
  ELSE
    SELECT "Bledny pesel";
  END IF;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS dynamiczne_prezes_stan_konta;
DELIMITER //
CREATE PROCEDURE dynamiczne_prezes_stan_konta(IN kol ENUM ('uzytkownik', 'saldo'),
                                              IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM stan_konta INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call dynamiczne_prezes_stan_konta("saldo","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_prezes_uzytkownicy;
DELIMITER //
CREATE PROCEDURE dynamiczne_prezes_uzytkownicy(IN kol ENUM ('PESEL', 'imie', 'nazwisko','data_dolaczenia', 'rola'),
                                               IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM uzytkownicy INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call dynamiczne_prezes_uzytkownicy("PESEL","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_prezes_zabiegi;
DELIMITER //
CREATE PROCEDURE dynamiczne_prezes_zabiegi(IN kol ENUM ('klient', 'pracownik','data_zabiegu', 'usluga', 'stanowisko', 'oplcaono'),
                                           IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM zabiegi INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call dynamiczne_prezes_zabiegi("klient","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_prezes_transakcje;
DELIMITER //
CREATE PROCEDURE dynamiczne_prezes_transakcje(IN kol ENUM ('odbiorca', 'placacy','kwota', 'data', 'opis'),
                                              IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM transakcje INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_prezes_transakcje("odbiorca","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_prezes_specjalizacje;
DELIMITER //
CREATE PROCEDURE dynamiczne_prezes_specjalizacje(IN kol ENUM ('pracownik', 'uprawnienia','pensja'),
                                                 IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM specjalizacje INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_prezes_specjalizacje("pensja","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_pracownik_dostep_do_stanowiska;
DELIMITER //
CREATE PROCEDURE dynamiczne_pracownik_dostep_do_stanowiska(IN kol ENUM ('stanowisko', 'wymagane uprawnienia'),
                                                           IN agg ENUM ('avg','count','max','min','sum'),
                                                           OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM dostep_do_stanowiska INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_pracownik_dostep_do_stanowiska("stanowisko","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_pracownik_stanowiska;
DELIMITER //
CREATE PROCEDURE dynamiczne_pracownik_stanowiska(IN kol ENUM ('nazwa', 'max_ilosc_osob'),
                                                 IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM stanowiska INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_pracownik_stanowiska("nazwa","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_pracownik_uprawnienia;
DELIMITER //
CREATE PROCEDURE dynamiczne_pracownik_uprawnienia(IN kol ENUM ('nazwa', 'nr', 'grupa'),
                                                  IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM uprawnienia INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_pracownik_uprawnienia("nazwa","count",@X);
# SELECT @X;

DROP PROCEDURE IF EXISTS dynamiczne_klient_uslugi;
DELIMITER //
CREATE PROCEDURE dynamiczne_klient_uslugi(IN kol ENUM ('ID', 'rodzaj', 'nazwa', 'czas_trwania', 'cena', 'uprawnienia'),
                                          IN agg ENUM ('avg','count','max','min','sum'), OUT X VARCHAR(100))
BEGIN
  SET @tempX = NULL;

  SET @query = CONCAT('SELECT ', agg, '(', kol, ') FROM uslugi_rehabilitacyjne INTO @tempX');
  PREPARE stmt FROM @query;
  EXECUTE stmt;
  DEALLOCATE PREPARE stmt;

  SET X = @tempX;
END//
DELIMITER ;
# call  dynamiczne_klient_uslugi("cena","max",@X);
# SELECT @X;


# CALL wyplac_pensje();
# CALL wyplac_premie(1, 1000);
# CALL zysk_w_ostatnich_dniach(date_sub(date(now()), INTERVAL 9 DAY), date(now()));
# CALL pracownik_miesiaca()
# CALL najczestszy_zabieg();
# CALL zaplata_za_zabieg('00211898694', '9829');
# CALL dodaj_nowe_stanowisko('xd', 1, 'Lasery A');
# CALL dodaj_uprawnienia_do_istniejacego_stanowiska(296, 'Lasery B');
# CALL dodaj_nowego_pracownika('11111111111', 'test', 'test', 'Lasery A', 12345);
# CALL dodaj_nowego_klienta('11111111119', 'test', 'test', 12345);
# CALL usun_zabieg(501);
# CALL usun_klienta('10282398601');
# CALL usun_pracownika('10323199895');
