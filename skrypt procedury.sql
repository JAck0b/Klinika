-- Tutaj są kody wszystkich procedur
DROP PROCEDURE IF EXISTS czy_jest_gdzie_wolne_miejsce;
DELIMITER //
CREATE PROCEDURE czy_jest_gdzie_wolne_miejsce(IN kiedy DATETIME, IN id_pracownika CHAR(11), IN id_uslugi INT,
                                              OUT czy_mozna BOOLEAN, OUT gdzie_wolne INT)
BEGIN
  DECLARE obecna_ilosc_osob INT DEFAULT 0;
  DECLARE maksymalna_liczba_osob INT DEFAULT 0;
  DECLARE czas_zaplanowanych_zabiegow INT DEFAULT 0;
  DECLARE uprawnienia_zaplanowanego_prowadzacego VARCHAR(45);
  DECLARE grupa_zaplanowanego_prowadzacego VARCHAR(45);
  DECLARE id_zaplanowanego_stanowiska INT;

  DECLARE czas_nowego_zabiegu INT DEFAULT 0;
  DECLARE uprawnienia_nowego_zabiegu VARCHAR(45);
  DECLARE grupa_nowego_zabiegu VARCHAR(45);

  SET czy_mozna = FALSE;
  SET gdzie_wolne = -1;

  # wszystkie zabiegi w danym momencie wykonywane przez podanego pracownika
  CREATE TEMPORARY TABLE zabiegi_pomoc
  SELECT *
  FROM zabiegi
  WHERE pracownik LIKE id_pracownika
    AND data_zabiegu LIKE kiedy;

  # znajdowanie uprawnień prowadzącego oraz jego grupy
  SELECT uprawnienia.nazwa, uprawnienia.grupa
  FROM specjalizacje
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE specjalizacje.uzytkownik LIKE id_pracownika
  LIMIT 1 INTO uprawnienia_zaplanowanego_prowadzacego, grupa_zaplanowanego_prowadzacego;

  # znajdowanie minimalnych uprawnień, grupy uprawnień oraz czasu nowego zebiegu
  SELECT uprawnienia.nazwa, uprawnienia.grupa, uslugi_rehabilitacyjne.czas_trwania
  FROM uslugi_rehabilitacyjne
         JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
  WHERE uslugi_rehabilitacyjne.ID = id_uslugi
  LIMIT 1 INTO uprawnienia_nowego_zabiegu, grupa_nowego_zabiegu, czas_nowego_zabiegu;

  # sprawdzenie, czy ten prowadzący w ogóle może prowadzić ten zabieg
  IF grupa_nowego_zabiegu LIKE grupa_zaplanowanego_prowadzacego AND
     uprawnienia_nowego_zabiegu <= uprawnienia_zaplanowanego_prowadzacego THEN

    # znajdowanie ile osób jest teraz umówionych i jakie jest id stanowiska na którym będzie zabieg
    SELECT count(ID), stanowisko
    FROM zabiegi_pomoc
    GROUP BY stanowisko INTO obecna_ilosc_osob, id_zaplanowanego_stanowiska;

    # znajdowanie czasu zaplanowanego zabiegu
    SELECT DISTINCT uslugi_rehabilitacyjne.czas_trwania
    FROM uslugi_rehabilitacyjne
           JOIN zabiegi_pomoc ON uslugi_rehabilitacyjne.ID = zabiegi_pomoc.usluga
    LIMIT 1 INTO czas_zaplanowanych_zabiegow;

    # znajdowanie jaka jest maksymalna liczba osób na danym stanowisku
    SELECT stanowiska.max_ilosc_osob
    FROM stanowiska
    WHERE ID = id_zaplanowanego_stanowiska INTO maksymalna_liczba_osob;

    IF obecna_ilosc_osob >= 1 AND obecna_ilosc_osob + 1 < maksymalna_liczba_osob AND
       czas_nowego_zabiegu = czas_zaplanowanych_zabiegow THEN
      # trzeba sprawdzic czy miejsce sie zgadza, czy czas jest ok oraz czy jest jeszcze miejsce

      SET czy_mozna = TRUE;
      SET gdzie_wolne = id_zaplanowanego_stanowiska;

    ELSE
      # trzeba znaleźć nowe puste stanowisko

      #       select stanowiska.ID
      #       from stanowiska
      #              join zabiegi on stanowiska.ID = zabiegi.stanowisko
      #              join dostep_do_stanowiska on stanowiska.nazwa = dostep_do_stanowiska.stanowisko
      #              join uprawnienia on dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
      #       where uprawnienia.nazwa like uprawnienia_nowego_zabiegu
      #         and uprawnienia.grupa like grupa_nowego_zabiegu
      #       having count(zabiegi.ID) = 0 limit 1 into gdzie_wolne;

      SELECT stanowiska.ID
      FROM stanowiska
             LEFT JOIN zabiegi ON stanowiska.ID = zabiegi.stanowisko
             JOIN dostep_do_stanowiska ON stanowiska.nazwa = dostep_do_stanowiska.stanowisko
             JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
      WHERE uprawnienia.grupa LIKE grupa_nowego_zabiegu
        AND zabiegi.data_zabiegu LIKE kiedy
      GROUP BY stanowiska.ID
      HAVING count(zabiegi.ID) = 0
      LIMIT 1 INTO gdzie_wolne;

      IF gdzie_wolne <> -1 THEN
        SET czy_mozna = TRUE;
      END IF;

    END IF;

  END IF;

END //
DELIMITER ;

# TODO można usunąć ilość i zostawić iterowanie po czasie
DROP PROCEDURE IF EXISTS wolne_miejsca;
DELIMITER //
CREATE PROCEDURE wolne_miejsca(IN data DATE, IN nazwa_uslugi VARCHAR(100), IN rodzaj_uslugi VARCHAR(50))
BEGIN
  DECLARE iterator INT DEFAULT 0;
  DECLARE warunek BOOLEAN DEFAULT 0; # warunek czy jest dobra procedura
  DECLARE rozpoczecie TIME; # godzina rozpoczęcia pracy w tym dniu
  DECLARE zakonczenie TIME; # godzina zakończenia pracy w tym dniu
  DECLARE ilosc INT; # ilość przejść pętli
  DECLARE czas_pomoc TIME; # iterator godzin
  DECLARE koniec BOOLEAN DEFAULT TRUE;
  DECLARE pracownik_pomoc CHAR(11);
  DECLARE id_uslugi INT;
  DECLARE id_stanowiska INT;
  DECLARE iterator CURSOR FOR (SELECT uzytkownicy.PESEL # trzeba unikać selectowania zabiegów
                               FROM uzytkownicy
                                      JOIN specjalizacje s ON uzytkownicy.PESEL = s.uzytkownik
                                      JOIN uprawnienia u ON s.uprawnienia = u.nazwa
                                      JOIN uslugi_rehabilitacyjne ur ON u.nazwa = ur.uprawnienia
                               WHERE ur.nazwa LIKE nazwa_uslugi
                                 AND ur.rodzaj LIKE rodzaj_uslugi
                                 AND uzytkownicy.rola LIKE 'Pracownik');
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET koniec = FALSE;

  SELECT godzina_zakonczenia
  FROM godziny_otwarcia
  WHERE ID = dayofweek(data)
  LIMIT 1 INTO zakonczenie;

  SELECT godzina_rozpoczecia
  FROM godziny_otwarcia
  WHERE ID = dayofweek(data)
  LIMIT 1 INTO rozpoczecie;

  SET ilosc = 4 * hour(timediff(zakonczenie, rozpoczecie));

  # ustalanie id danej usługi
  SELECT ID
  FROM uslugi_rehabilitacyjne
  WHERE nazwa LIKE nazwa_uslugi
    AND rodzaj LIKE rodzaj_uslugi
  LIMIT 1
    INTO id_uslugi;

  # można zmienić na wyszukiwanie dla każdego pracownika osobno, ale chyba lepiej tak
  CREATE TEMPORARY TABLE zabiegi_pomoc
  SELECT *
  FROM zabiegi
  WHERE usluga = id_uslugi
    AND data_zabiegu LIKE data;

  # tworzenie tablicy wyników
  DROP TABLE IF EXISTS wynik;
  CREATE TABLE wynik
  (
    pracownik  CHAR(11) NOT NULL,
    godzina    TIME     NOT NULL,
    stanowisko INT      NOT NULL
  );

  # chodzę po wszystkich pracownikach, którzy mogą prowadzić ten zabieg
  OPEN iterator;
  FETCH iterator INTO pracownik_pomoc;

  WHILE koniec <> FALSE DO

  # chodzę po wszystkich
  SET czas_pomoc = rozpoczecie;
  SET iterator = 0;
  WHILE iterator < ilosc DO

  # procedura do której wrzucam pracownika, czas, usluge i zwraca mi czy moge gdzieś wrzucic osobe i gdzie
  CALL czy_jest_gdzie_wolne_miejsce(concat(data, ' ', czas_pomoc), pracownik_pomoc, id_uslugi, warunek, id_stanowiska);

  IF (warunek = TRUE) THEN
    INSERT INTO wynik (pracownik, godzina, stanowisko)
    VALUES (pracownik_pomoc, czas_pomoc, id_stanowiska);
  END IF ;

  SET czas_pomoc = addtime(czas_pomoc, '15:00');
  SET iterator = iterator = 1;
  END WHILE;


  FETCH iterator INTO pracownik_pomoc;
  END WHILE;

  SELECT * FROM wynik;

  DROP TEMPORARY TABLE IF EXISTS zabiegi_pomoc;
  DROP TABLE IF EXISTS wynik;

END //
DELIMITER ;

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

  SET ilosc_dni = datediff( data_konca, data_poczatku);
  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes'
    INTO pesel_menagera;

  WHILE i <= ilosc_dni DO

    SELECT sum(kwota)
    FROM transakcje
    WHERE odbiorca = pesel_menagera
      AND data = date_sub(data_konca, INTERVAL i DAY) INTO przychod;

    SELECT sum(kwota)
    FROM transakcje
    WHERE placacy = pesel_menagera
      AND data = date_sub(data_konca, INTERVAL i DAY) INTO wydatki;

    IF NOT ISNULL(przychod) THEN  #w danzm dniu moe nie bz transkacji wtedy null wsyztkow psuje
      SET zysk = zysk + przychod;
    END IF;
    IF NOT ISNULL(wydatki) THEN  #w danzm dniu moe nie bz transkacji wtedy null wsyztkow psuje
      SET zysk = zysk - wydatki;
    END IF;

    SET i = i + 1;
  END WHILE;
  SELECT zysk;
END//
DELIMITER ;
#call zysk_w_ostatnich_dniach(date_sub(date(now()), INTERVAL 9 DAY), date(now()));

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
  START TRANSACTION;
    DROP TEMPORARY TABLE IF EXISTS T;
    CREATE TEMPORARY TABLE T AS SELECT pensja, pracownik FROM specjalizacje;
    w: WHILE i < liczba_pracownikow  DO
      SET pensja_pracownika = (SELECT pensja FROM T LIMIT i,1);
      SET pesel_pracownika = (SELECT pracownik FROM T LIMIT i,1);
      SET budzet = budzet - pensja_pracownika;
      CALL doladowanie_konta(pesel_menagera, - pensja_pracownika);
      INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis) VALUES
        (pesel_pracownika,pesel_menagera,current_date(),pensja_pracownika,'pensja');
      SET i = i + 1;
    END WHILE;

    IF (budzet >= 0) THEN
      SELECT "Wyplaty zakonczone";
      COMMIT;
    ELSE
      SELECT "Brak srodkow!";
      ROLLBACK;
    END IF;
    DROP TEMPORARY TABLE T;
END//
DELIMITER ;
#CALL wyplac_pensje();

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
  START TRANSACTION;
    DROP TEMPORARY TABLE IF EXISTS T;

    #znajduje pracownika ktorzy wykoanli najwiecej zabiegow w tym miesiacu
    # (w tabeli zabiegi jak zabieg jest dla większej liczby osboób występuje kilka kronie)
    CREATE TEMPORARY TABLE T
      AS SELECT x.pracownik, count(x.data_zabiegu) as pom FROM
          (SELECT DISTINCT pracownik, data_zabiegu FROM zabiegi WHERE month(data_zabiegu) = month(current_date())) as x
        GROUP BY x.pracownik ORDER BY pom DESC LIMIT liczba_pracownikow;

    w: WHILE i < liczba_pracownikow  DO
      SET pesel_pracownika = (SELECT pracownik FROM T LIMIT i,1);
      SET budzet = budzet - kwota_premi;
      CALL doladowanie_konta(pesel_menagera, - kwota_premi);
      INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis) VALUES
        (pesel_pracownika,pesel_menagera,current_date(),kwota_premi,'premia');
      SET i = i + 1;
    END WHILE;

    IF (budzet >= 0) THEN
      SELECT "Wyplaty zakonczone";
      COMMIT;
    ELSE
      SELECT "Brak srodkow!";
      ROLLBACK;
    END IF;
    DROP TEMPORARY TABLE T;
END//
DELIMITER ;
#CALL wyplac_premie(1,1000);

DROP PROCEDURE IF EXISTS pracownik_miesiaca;
DELIMITER //
CREATE PROCEDURE pracownik_miesiaca()
BEGIN
  SELECT x.pracownik as pracownik_miesiaca FROM
    (SELECT DISTINCT pracownik, data_zabiegu FROM zabiegi WHERE month(data_zabiegu) = month(current_date())) as x
  GROUP BY x.pracownik ORDER BY count(data_zabiegu) DESC LIMIT 1 ;

END//
DELIMITER ;
#CALL pracownik_miesiaca()

DROP PROCEDURE IF EXISTS najczestszy_zabieg;
DELIMITER //
CREATE PROCEDURE najczestszy_zabieg()
BEGIN
  SELECT nazwa as najczestszy_zabieg FROM
    (SELECT DISTINCT usluga, data_zabiegu FROM zabiegi) as x JOIN uslugi_rehabilitacyjne ON x.usluga = uslugi_rehabilitacyjne.ID
  GROUP BY x.usluga ORDER BY count(data_zabiegu) DESC LIMIT 1 ;

END//
DELIMITER ;
#CALL najczestszy_zabieg();

DROP PROCEDURE IF EXISTS zaplata_za_zabieg;
DELIMITER //
CREATE PROCEDURE zaplata_za_zabieg(IN pesel_klienta  CHAR(11), IN id_zabiegu INT)
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
  WHERE ID = id_zabiegu AND klient = pesel_klienta INTO rodzaj_uslugi, stan;

  SELECT saldo
  FROM stan_konta
  WHERE uzytkownik = pesel_klienta INTO stan_konta_klienta;

  SELECT cena
  FROM uslugi_rehabilitacyjne
  WHERE ID = rodzaj_uslugi INTO cena_zabiegu;

  IF (stan = 'nie') THEN
    SET autocommit = 0;
    START TRANSACTION;

    SET stan_konta_klienta = stan_konta_klienta - cena_zabiegu;
    CALL doladowanie_konta(pesel_menagera, cena_zabiegu);
    CALL doladowanie_konta(pesel_klienta, -cena_zabiegu);
    INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis) VALUES
    (pesel_menagera,pesel_klienta,current_date(),cena_zabiegu,'za_zabieg');
    UPDATE zabiegi SET oplacono = 'tak' WHERE ID = id_zabiegu;

    IF (stan_konta_klienta >= 0) THEN
      SELECT "Zaplacono";
      COMMIT;
    ELSE
      SELECT "Brak srodkow!";
      ROLLBACK;
    END IF;
  ELSE
    SELECT "Juz oplacono";
  END IF;


END//
DELIMITER ;
#CALL zaplata_za_zabieg('00211898694','9829');