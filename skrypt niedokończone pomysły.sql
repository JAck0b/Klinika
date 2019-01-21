-- Tutaj są kody wszystkich procedur

# todo naprawić to, by się nie dało zapisać po godzinach pracy
# todo zamienić porównywanie dat na integery i staram się nie używać datatime (zamiast tego time)

DROP PROCEDURE IF EXISTS czy_jest_gdzies_wolne_miejsce;
DROP PROCEDURE IF EXISTS wolne_miejsca;

DELIMITER //
CREATE PROCEDURE czy_jest_gdzies_wolne_miejsce(IN kiedy DATETIME,
                                               IN nowe_uprawnienia_nazwa VARCHAR(45),
                                               IN nowe_uprawnienia_grupa VARCHAR(45),
                                               IN nowa_usluga_czas_trwania INT,
                                               OUT czy_mozna BOOLEAN, OUT gdzie_wolne INT, OUT kto_moze CHAR(11))
BEGIN
  DECLARE iterator_pracownikow INT DEFAULT 0;
  DECLARE iterator_stanowisk INT DEFAULT 0;
  DECLARE iterator_godziny DATETIME;
  DECLARE iterator_godziny_wewnetrzny DATETIME;
#   DECLARE
  DECLARE dlugosc_iterowanego_zabiegu INT;
  DECLARE ilosc_stanowisk INT;
  DECLARE ilosc_pracownikow INT;
  DECLARE suma INT;
  DECLARE znalazlem_stanowisko BOOLEAN DEFAULT FALSE;
  DECLARE iterowane_stanowisko INT;
  DECLARE znalazlem_pracownika BOOLEAN DEFAULT FALSE;
  DECLARE iterowany_pracownik CHAR(11);
  DECLARE najdluzsza_usluga INT;
  DECLARE koniec_petli BOOLEAN DEFAULT FALSE;
  DECLARE minimalna_godzina DATETIME;
  DECLARE maksymalna_godzina DATETIME;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET koniec_petli = TRUE;

  SET czy_mozna = FALSE;

  SELECT max(uslugi_rehabilitacyjne.czas_trwania)
  FROM uslugi_rehabilitacyjne INTO najdluzsza_usluga;

  SELECT count(stanowiska.ID)
  FROM stanowiska INTO ilosc_stanowisk;

  SELECT count(PESEL)
  FROM uzytkownicy
  WHERE uzytkownicy.rola LIKE 'Pracownik' INTO ilosc_pracownikow;

  SELECT 'tworze zajete_stanowiska';

  DROP TABLE IF EXISTS odpowiadajace_stanowiska;
  CREATE TABLE odpowiadajace_stanowiska
  (
    ID INT
  );

  INSERT INTO odpowiadajace_stanowiska (ID)
  SELECT stanowiska.ID
  FROM stanowiska
         JOIN dostep_do_stanowiska ON stanowiska.ID = dostep_do_stanowiska.stanowisko
         JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.nazwa <= nowe_uprawnienia_nazwa
    AND uprawnienia.grupa = nowe_uprawnienia_grupa;

  # tworzenie siatki dostępności stanowisk o danych godzinach
  DROP TABLE IF EXISTS zajete_stanowiska;
  CREATE TABLE zajete_stanowiska
  (
    czas       DATETIME,
    stanowisko INT,
    czy_zajete BOOLEAN
  );

  SELECT 'uzupelniam -zajete_stanowiska';

  SET minimalna_godzina = subdate(kiedy, INTERVAL najdluzsza_usluga MINUTE);
  SET maksymalna_godzina = date_add(kiedy, INTERVAL nowa_usluga_czas_trwania MINUTE);


  SET iterator_stanowisk = 0;
  SET koniec_petli = FALSE;
  WHILE koniec_petli = FALSE DO
  SET iterator_godziny = minimalna_godzina;
  WHILE iterator_godziny < maksymalna_godzina DO
  INSERT INTO zajete_stanowiska (czas, stanowisko, czy_zajete)
  VALUES (iterator_godziny, iterator_stanowisk, FALSE);
  SET iterator_godziny = date_add(iterator_godziny, INTERVAL 15 MINUTE);
  END WHILE ;
  SELECT iterator_stanowisk;
  SET iterator_stanowisk = iterator_stanowisk + 1;
  END WHILE;

  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'dkafja';

  SELECT 'tworze zajetych pracownków';

  DROP TABLE IF EXISTS zajeci_pracownicy;
  CREATE TABLE zajeci_pracownicy
  (
    czas       DATETIME,
    pracownik  CHAR(11),
    czy_zajete BOOLEAN
  );

  SELECT 'uzupelniam -zajetych_pracowników';

  SET iterator_pracownikow = 0;
  WHILE iterator_pracownikow < ilosc_pracownikow DO
  SET iterator_godziny = minimalna_godzina;
  WHILE iterator_godziny < maksymalna_godzina DO
  INSERT INTO zajeci_pracownicy (czas, pracownik, czy_zajete)
  VALUES (iterator_godziny, iterator_pracownikow, FALSE);
  SET iterator_godziny = date_add(iterator_godziny, INTERVAL 15 MINUTE);
  END WHILE ;
  SET iterator_pracownikow = iterator_pracownikow + 1;
  END WHILE;


  SELECT 'tworze info o zabiegach';


  DROP TABLE IF EXISTS zabiegi_informacje;
  CREATE TABLE zabiegi_informacje
  (
    data_zabiegu DATETIME,
    czas_trwania INT,
    stanowisko   INT,
    pracownik    CHAR(11)
  );

  SELECT 'uzupelniam info o zabiegach';


  INSERT INTO zabiegi_informacje (data_zabiegu, czas_trwania, stanowisko, pracownik)
  SELECT DISTINCT zabiegi.data_zabiegu, uslugi_rehabilitacyjne.czas_trwania, zabiegi.stanowisko, zabiegi.pracownik
  FROM zabiegi
         JOIN uslugi_rehabilitacyjne ON zabiegi.usluga = uslugi_rehabilitacyjne.ID
  WHERE zabiegi.data_zabiegu <= maksymalna_godzina
    AND zabiegi.data_zabiegu >= minimalna_godzina;


  SELECT 'uzupelnianie tej wielkiej siatki stanowisk';

  # wypełnianie tej tablicy, w której jest siatke dostępności stanowisk
  SET iterator_stanowisk = 0;
  WHILE iterator_stanowisk < ilosc_stanowisk DO
  SET iterator_godziny = minimalna_godzina;
  WHILE iterator_godziny < maksymalna_godzina DO
  SET iterator_godziny_wewnetrzny = iterator_godziny;
  SET dlugosc_iterowanego_zabiegu = 0;
  SET koniec_petli = FALSE;
  SELECT zabiegi_informacje.czas_trwania
  FROM zabiegi_informacje
  WHERE data_zabiegu = iterator_godziny
    AND stanowisko = iterator_stanowisk
  LIMIT 1
    INTO dlugosc_iterowanego_zabiegu;
  IF koniec_petli = FALSE THEN
    WHILE iterator_godziny_wewnetrzny < date_add(iterator_godziny, INTERVAL dlugosc_iterowanego_zabiegu MINUTE) DO
    UPDATE zajete_stanowiska
    SET zajete_stanowiska.czy_zajete = TRUE
    WHERE zajete_stanowiska.czas = iterator_godziny_wewnetrzny
      AND stanowisko = iterator_stanowisk;
    SET iterator_godziny_wewnetrzny = date_add(iterator_godziny_wewnetrzny, INTERVAL 15 MINUTE);
    END WHILE;
  END IF ;
  SET iterator_godziny = date_add(iterator_godziny, INTERVAL 15 MINUTE);
  END WHILE ;
  SET iterator_stanowisk = iterator_stanowisk + 1;
  END WHILE;

  SELECT 'uzupelnianie tej wielkiej siatki pracownikow';

  # wypełnianie tej tablicy, w której jest siatke dostępności pracowników
  SET iterator_pracownikow = 0;
  WHILE iterator_pracownikow < ilosc_pracownikow DO
  SET iterator_godziny = minimalna_godzina;
  WHILE iterator_godziny < maksymalna_godzina DO
  SET iterator_godziny_wewnetrzny = iterator_godziny;
  SET dlugosc_iterowanego_zabiegu = 0;
  SET koniec_petli = FALSE;
  SELECT zabiegi_informacje.czas_trwania
  FROM zabiegi_informacje
  WHERE data_zabiegu = iterator_godziny
    AND pracownik = iterator_pracownikow
  LIMIT 1
    INTO dlugosc_iterowanego_zabiegu;
  IF koniec_petli = FALSE THEN
    WHILE iterator_godziny_wewnetrzny < date_add(iterator_godziny, INTERVAL dlugosc_iterowanego_zabiegu MINUTE) DO
    UPDATE zajeci_pracownicy
    SET zajeci_pracownicy.czy_zajete = TRUE
    WHERE zajeci_pracownicy.czas = iterator_godziny_wewnetrzny
      AND pracownik = iterator_pracownikow;
    SET iterator_godziny_wewnetrzny = date_add(iterator_godziny_wewnetrzny, INTERVAL 15 MINUTE);
    END WHILE;
  END IF ;
  SET iterator_godziny = date_add(iterator_godziny, INTERVAL 15 MINUTE);
  END WHILE ;
  SET iterator_pracownikow = iterator_pracownikow + 1;
  END WHILE;

  SELECT 'liczenie tych rzeczy';


  SELECT count(stanowiska.ID)
  FROM stanowiska
         JOIN dostep_do_stanowiska ON stanowiska.ID = dostep_do_stanowiska.stanowisko
         JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa <= nowe_uprawnienia_nazwa INTO ilosc_stanowisk;

  SELECT count(uzytkownicy.PESEL)
  FROM uzytkownicy
         JOIN specjalizacje ON uzytkownicy.PESEL = specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa >= nowe_uprawnienia_nazwa INTO ilosc_pracownikow;

  SELECT 'wszstko wypelnilem';


  szukanie_stanowiska: WHILE iterator_stanowisk < ilosc_stanowisk DO
  SET suma = -1;

  SELECT zajete_stanowiska.stanowisko, sum(zajete_stanowiska.czy_zajete)
  FROM zajete_stanowiska
         JOIN stanowiska ON zajete_stanowiska.stanowisko = stanowiska.ID
         JOIN dostep_do_stanowiska ON stanowiska.ID = dostep_do_stanowiska.stanowisko
         JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa <= nowe_uprawnienia_nazwa
  GROUP BY zajete_stanowiska.stanowisko INTO iterowane_stanowisko,suma;

  IF suma = 0 THEN
    SET gdzie_wolne = iterowane_stanowisko;
    SET znalazlem_stanowisko = TRUE;
    LEAVE szukanie_stanowiska;
  END IF ;

  # noinspection SqlUnreachable

  SET iterator_stanowisk = iterator_stanowisk + 1;
  END WHILE;


  szukanie_pracownika: WHILE iterator_pracownikow < ilosc_pracownikow DO
  SET suma = -1;

  SELECT zajeci_pracownicy.pracownik, sum(zajeci_pracownicy.czy_zajete)
  FROM zajeci_pracownicy
         JOIN uzytkownicy ON zajeci_pracownicy.pracownik = uzytkownicy.PESEL
         JOIN specjalizacje ON uzytkownicy.PESEL = specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa >= nowe_uprawnienia_nazwa
  GROUP BY zajeci_pracownicy.pracownik INTO iterowany_pracownik, suma;

  IF suma = 0 THEN
    SET kto_moze = iterowany_pracownik;
    SET znalazlem_pracownika = TRUE;
    LEAVE szukanie_pracownika;
  END IF ;

  # noinspection SqlUnreachable

  SET iterator_pracownikow = iterator_pracownikow + 1;
  END WHILE;

  IF znalazlem_pracownika = TRUE AND znalazlem_stanowisko = TRUE THEN
    SET czy_mozna = TRUE;
  END IF;


  DROP TABLE IF EXISTS zajete_stanowiska;
  DROP TABLE IF EXISTS zajeci_pracownicy;
  DROP TABLE IF EXISTS zabiegi_informacje;

END //
DELIMITER ;


# TODO można usunąć ilość i zostawić iterowanie po czasie
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
#   DECLARE pomocniczy_warunek BOOLEAN DEFAULT FALSE;
  DECLARE znalezione_stanowisko INT DEFAULT 0;
  DECLARE maksymalna_ilosc_stanowiska INT DEFAULT 0;
  DECLARE obecna_ilosc_stanowiska INT DEFAULT 0;
  DECLARE uprawnienia_pracownika_nazwa VARCHAR(45) DEFAULT '';
  DECLARE uprawnienia_pracownika_grupa VARCHAR(45) DEFAULT '';
  DECLARE uprawnienia_salki_nazwa VARCHAR(45) DEFAULT '';
  DECLARE uprawnienia_salki_grupa VARCHAR(45) DEFAULT '';
  DECLARE nowa_usluga_czas_trwania INT DEFAULT 0;
#   DECLARE iterowana_usluga_czas_trwania INT DEFAULT 0;
  DECLARE imie_pracownika VARCHAR(30) DEFAULT '';
  DECLARE nazwisko_pracownika VARCHAR(30) DEFAULT '';
  DECLARE id_pracownika CHAR(11) DEFAULT '';
  DECLARE id_stanowiska INT DEFAULT 0;
#   DECLARE czy_znaleziono BOOLEAN DEFAULT FALSE;
  DECLARE ilosc_zabiegow INT DEFAULT -1;
  DECLARE najdluzsza_usluga_tego_typu INT DEFAULT -1;
  DECLARE minimalna_godzina TIME;
  DECLARE maksymalna_godzina TIME;
  DECLARE ilosc_pasujacych_stanowisk INT DEFAULT -1;
  DECLARE ilosc_pasujacych_pracownikow INT DEFAULT -1;
  DECLARE pomocniczy_char CHAR(32);
  DECLARE znaleziono_stanowisko BOOLEAN DEFAULT TRUE;
  DECLARE znaleziono_pracownika BOOLEAN DEFAULT TRUE;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET koniec_petli = TRUE;

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

  SET ilosc_iteracji_godzin = 32; # potem to można zmienić na jakieś mądre wyliczanie

  SET iterator_godzin_wlasciwy = godzina_rozpoczecia;

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


  SELECT max(uslugi_rehabilitacyjne.czas_trwania)
  FROM uslugi_rehabilitacyjne
         JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.nazwa <= nowe_uprawnienia_nazwa
    AND uprawnienia.grupa = nowe_uprawnienia_grupa INTO najdluzsza_usluga_tego_typu;



  # tutaj będą składowane wszystkie możliwe terminy zapisóœ
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
    PESEL    CHAR(11),
    imie     VARCHAR(30),
    nazwisko VARCHAR(30)
  );
  INSERT INTO pracownicy_pomoc (PESEL, imie, nazwisko)
  SELECT DISTINCT uzytkownicy.PESEL, uzytkownicy.imie, uzytkownicy.nazwisko
  FROM uzytkownicy
         JOIN specjalizacje ON uzytkownicy.PESEL = specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.grupa = nowe_uprawnienia_grupa
    AND uprawnienia.nazwa >= nowe_uprawnienia_nazwa
    AND rola LIKE 'Pracownik';

  SELECT *
    FROM pracownicy_pomoc;


  # biorę tylko potrzebne stanowiska, pracownika potem będzie trzeba sprawdzać
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

#     SELECT *
#     FROM odpowiednie_zabiegi;

  DROP TABLE IF EXISTS zajete_stanowiska;
  CREATE TABLE zajete_stanowiska
  (
    stanowisko INT,
    czy_zajete CHAR(32)
  );

  # wylicznie siatki dla stanowisk//////////////////////////////////////////////////////

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

#     SELECT iterator_godzin_wlasciwy;

    WHILE iterator_godzin_int < ilosc_iteracji_godzin DO

      SET iterator_godzin_int_wewnetrzy = 0;
      SET ilosc_iteracji_godzin_wewnetrznych = -1;

      SELECT odpowiednie_zabiegi.czas_trwania
      FROM odpowiednie_zabiegi
      WHERE odpowiednie_zabiegi.stanowisko = id_stanowiska
        AND czas_zabiegu LIKE iterator_godzin_wlasciwy
        INTO ilosc_iteracji_godzin_wewnetrznych;

#       SELECT ilosc_iteracji_godzin_wewnetrznych, iterator_godzin_wlasciwy;
#       SELECT ilosc_iteracji_godzin_wewnetrznych;

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

  SELECT *
    FROM zajete_stanowiska;



    DROP TABLE IF EXISTS zajeci_pracownicy;
    CREATE TABLE zajeci_pracownicy
    (
      pracownik CHAR(11),
      czy_zajete CHAR(32)
    );


  # wyliczanie tej siatki dla pracowników //////////////////////////////////////////////////////

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

  SELECT *
    FROM zajeci_pracownicy;




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

  SET iterator_godzin_int = 0;
  SET iterator_godzin_wlasciwy = godzina_rozpoczecia;
  petla_godzin: WHILE iterator_godzin_int < ilosc_iteracji_godzin DO
  SET iterator_zabiegow = 0;
  SET koniec_petli = FALSE;
  SELECT count(*)
  FROM zabiegi_pomoc
  WHERE czas_zabiegu LIKE iterator_godzin_wlasciwy
  INTO ilosc_zabiegow;
  petla_zabiegi: WHILE iterator_zabiegow < ilosc_zabiegow DO

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
#     SELECT 'jestem w if';

    ELSE
      # tutaj trzeba znaleźć nowe stanowisko i pracownika

      SET ilosc_iteracji_godzin_wewnetrznych = nowa_usluga_czas_trwania/15;
      SET iterator_godzin_int_wewnetrzy = 0;
      set znalezione_stanowisko = TRUE;

      WHILE iterator_godzin_int_wewnetrzy < ilosc_iteracji_godzin_wewnetrznych DO

        IF

        SET iterator_godzin_int_wewnetrzy = iterator_godzin_int_wewnetrzy + 1;
      END WHILE ;

#       SET czy_znaleziono = FALSE;
#       CALL czy_jest_gdzies_wolne_miejsce(concat(data, ' ', iterator_godzin), nowe_uprawnienia_nazwa,
#                                          nowe_uprawnienia_grupa, nowa_usluga_czas_trwania, czy_znaleziono,
#                                          id_stanowiska, id_pracownika);
#
#
#       IF czy_znaleziono = TRUE THEN
#
#         SELECT uzytkownicy.imie, uzytkownicy.nazwisko
#         FROM uzytkownicy
#         WHERE uzytkownicy.PESEL LIKE id_pracownika INTO imie_pracownika, nazwisko_pracownika;
#
#         INSERT INTO mozliwe_terminy (imie, nazwisko, stanowisko, godzina)
#         VALUES (imie_pracownika, nazwisko_pracownika, id_stanowiska, iterator_godzin);

      #       END IF;

      SET koniec_petli = FALSE;

  END IF ;

#   LEAVE petla_zabiegi;

  SET iterator_zabiegow = iterator_zabiegow + 1;
  END WHILE ;
#     LEAVE petla_godzin;
  SET iterator_godzin_wlasciwy = date_add(iterator_godzin_wlasciwy, INTERVAL 15 MINUTE );
  SET iterator_godzin_int = iterator_godzin_int + 1;
  END WHILE;

  SELECT *
  FROM mozliwe_terminy;


#   DROP TABLE IF EXISTS stanowiska_pomoc;
#   DROP TABLE IF EXISTS pracownicy_pomoc;
  DROP TABLE IF EXISTS zabiegi_pomoc;
  DROP TABLE IF EXISTS mozliwe_terminy;
END //
DELIMITER ;

CALL wolne_miejsca('2019-01-19', 'Argonowy', 'Laseroterapia');

# CALL czy_jest_gdzies_wolne_miejsce('2019-01-19 8:00:00', 'Lasery A', 'Lasery', 30, @czy_znal, @id_stan, @id_prac);
# SELECT @czy_znal, @id_stan, @id_prac;


# SELECT if('12:00:00' < '2019-01-19 12:00:01', 1, 0);
