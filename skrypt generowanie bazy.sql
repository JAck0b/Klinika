CREATE DATABASE klinika DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE uzytkownicy
(
  PESEL           CHAR(11)                               NOT NULL PRIMARY KEY,
  imie            VARCHAR(30)                            NOT NULL,
  nazwisko        VARCHAR(30)                            NOT NULL,
  data_dolaczenia DATE                                   NOT NULL,
  rola            ENUM ('Prezes', 'Pracownik', 'Klient') NOT NULL COMMENT 'Trzy podstawowe rodzaje uzytkownikow.'
);

CREATE TABLE uprawnienia
(
  nr    INT         NOT NULL,
  nazwa VARCHAR(45) NOT NULL PRIMARY KEY,
  grupa VARCHAR(45) NOT NULL
);

CREATE TABLE uslugi_rehabilitacyjne
(
  ID           INT          NOT NULL PRIMARY KEY AUTO_INCREMENT,
  rodzaj       VARCHAR(50)  NOT NULL,
  nazwa        VARCHAR(100) NOT NULL,
  czas_trwania INT          NOT NULL,
  cena         INT          NOT NULL,
  uprawnienia  VARCHAR(45)  NOT NULL,
  CONSTRAINT uprawnieniaU
    FOREIGN KEY (uprawnienia)
      REFERENCES uprawnienia (nazwa)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
);

CREATE TABLE transakcje
(
  ID       INT                                           NOT NULL PRIMARY KEY AUTO_INCREMENT,
  odbiorca CHAR(11)                                      NOT NULL,
  CONSTRAINT odbiorcaT
    FOREIGN KEY (odbiorca)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  placacy  CHAR(11)                                      NOT NULL,
  CONSTRAINT placacyT
    FOREIGN KEY (placacy)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  data     DATE                                          NOT NULL,
  kwota    INT                                           NOT NULL,
  opis     ENUM ('pensja', 'za_zabieg', 'zwrot', 'premia', 'inne') NOT NULL
);

CREATE TABLE stanowiska
(
  ID             INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
  nazwa          VARCHAR(45) NOT NULL,
  max_ilosc_osob INT         NOT NULL
);

CREATE TABLE zabiegi
(
  ID           INT      NOT NULL PRIMARY KEY AUTO_INCREMENT,
  klient       CHAR(11) NOT NULL,
  CONSTRAINT klientZ
    FOREIGN KEY (klient)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  pracownik    CHAR(11) NOT NULL,
  CONSTRAINT pracownikZ
    FOREIGN KEY (pracownik)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  data_zabiegu DATETIME NOT NULL,
  usluga       INT      NOT NULL,
  CONSTRAINT uslugaZ
    FOREIGN KEY (usluga)
      REFERENCES uslugi_rehabilitacyjne (ID)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  stanowisko   INT      NOT NULL,
  CONSTRAINT stanowiskoZ
    FOREIGN KEY (stanowisko)
      REFERENCES stanowiska (ID)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  oplacono ENUM ('tak', 'nie') NOT NULL

);

CREATE TABLE stan_konta
(
  uzytkownik CHAR(11) NOT NULL,
  CONSTRAINT uzytkownikS
    FOREIGN KEY (uzytkownik)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  saldo      INT      NOT NULL
);

CREATE TABLE specjalizacje
(
  pracownik   CHAR(11)    NOT NULL,
  uprawnienia VARCHAR(45) NOT NULL,
  pensja      INT         NOT NULL,
  CONSTRAINT pracownikSp
    FOREIGN KEY (pracownik)
      REFERENCES uzytkownicy (PESEL)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  CONSTRAINT uprawnieniaSp
    FOREIGN KEY (uprawnienia)
      REFERENCES uprawnienia (nazwa)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
);

CREATE TABLE dokumentacja
(
  data                      DATETIME     NOT NULL PRIMARY KEY,
  nazwa_obiektu_testowanego VARCHAR(50)  NOT NULL,
  czas                      INT          NOT NULL COMMENT 'Czas jest podawany w sekundach.',
  ilosc_rekodrow            INT          NOT NULL,
  komentarz                 VARCHAR(100) NOT NULL
);

CREATE TABLE dostep_do_stanowiska
(
  stanowisko           INT         NOT NULL,
  CONSTRAINT stanowiskoD
    FOREIGN KEY (stanowisko)
      REFERENCES stanowiska (ID)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION,
  wymagane_uprawnienia VARCHAR(45) NOT NULL,
  CONSTRAINT wymagane_uprawnieniaD
    FOREIGN KEY (wymagane_uprawnienia)
      REFERENCES uprawnienia (nazwa)
      ON UPDATE NO ACTION
      ON DELETE NO ACTION
);

CREATE TABLE godziny_otwarcia
(
  ID                  INT         NOT NULL PRIMARY KEY,
  nazwa               VARCHAR(15) NOT NULL,
  godzina_rozpoczecia TIME        NOT NULL,
  godzina_zakonczenia TIME        NOT NULL
);


insert into godziny_otwarcia (ID, nazwa, godzina_rozpoczecia, godzina_zakonczenia)
VALUES (1, 'Niedziela', '08:00:00', '16:00:00'),
       (2, 'Poniedzialek', '08:00:00', '16:00:00'),
       (3, 'Wtorek', '08:00:00', '16:00:00'),
       (4, 'Sroda', '08:00:00', '16:00:00'),
       (5, 'Czwartek', '08:00:00', '16:00:00'),
       (6, 'Piatek', '08:00:00', '16:00:00'),
       (7, 'Sobota', '08:00:00', '16:00:00');

INSERT INTO uprawnienia(nr, nazwa, grupa)
VALUES (1, 'Lasery A', 'Lasery'),
       (2, 'Lasery B', 'Lasery'),
       (3, 'Lasery C', 'Lasery'),
       (4, 'Lasery D', 'Lasery'),
       (5, 'Pole magnetyczne A', 'Pole magnetyczne'),
       (6, 'Pole magnetyczne B', 'Pole magnetyczne'),
       (7, 'Elektroterapia A', 'Elektroterapia'),
       (8, 'Elektroterapia C', 'Elektroterapia'),
       (9, 'Elektroterapia B', 'Elektroterapia'),
       (10, 'Ultradźwięki', 'Ultradźwięki'),
       (11, 'Gimnastyka C', 'Gimnastyka'),
       (12, 'Gimnastyka B', 'Gimnastyka'),
       (13, 'Gimnastyka A', 'Gimnastyka'),
       (14, 'Gimnastyka D', 'Gimnastyka'),
       (15, 'Fizjoterapia A', 'Fizjoterapia'),
       (16, 'Masaż mechaniczny', 'Masaż'),
       (17, 'Krioterapia C', 'Krioterapia'),
       (18, 'Krioterapia B', 'Krioterapia'),
       (19, 'Krioterapia A', 'Krioterapia'),
       (20, 'Lampy A', 'Lampy'),
       (21, 'Gimnastyka dziecko', 'Gimnastyka'),
       (22, 'Gimnastyka dorośli', 'Gimnastyka'),
       (23, 'Gimnastyka grupy', 'Gimnastyka'),
       (24, 'Akupunktura A', 'Akupunktura'),
       (25, 'Akupunktura C', 'Akupunktura'),
       (26, 'Akupunktura B', 'Akupunktura'),
       (27, 'Akupunktura D', 'Akupunktura'),
       (28, 'Masaż relaksacyjny B', 'Masaż'),
       (29, 'Masaż relaksacyjny C', 'Masaż'),
       (30, 'Masaż relaksacyjny A', 'Masaż'),
       (31, 'Kinesiotaping C', 'Kinesiotaping'),
       (32, 'Kinesiotaping B', 'Kinesiotaping'),
       (33, 'Kinesiotaping A', 'Kinesiotaping'),
       (34, 'Masaż kobiet', 'Masaż'),
       (35, 'Drenaż A', 'Drenaż'),
       (36, 'Drenaż B', 'Drenaż'),
       (37, 'Masaż klasyczny A', 'Masaż'),
       (38, 'Masaż klasyczny C', 'Masaż'),
       (39, 'Masaż klasyczny B', 'Masaż');

INSERT INTO uslugi_rehabilitacyjne (rodzaj, nazwa, czas_trwania, cena, uprawnienia)
VALUES ('Laseroterapia', 'Argonowy', 30, 10, 'Lasery A'),
       ('Laseroterapia', 'Barwnikowy o długim impulsie', 30, 10, 'Lasery A'),
       ('Laseroterapia', 'Miedziowy', 30, 10, 'Lasery B'),
       ('Laseroterapia', 'KTP', 30, 10, 'Lasery B'),
       ('Laseroterapia', 'Półprzewodnikowy', 30, 10, 'Lasery A'),
       ('Laseroterapia', 'Nd-YAG', 30, 10, 'Lasery D'),
       ('Laseroterapia', 'Diodowy', 30, 10, 'Lasery A'),
       ('Laseroterapia', 'Alekasndrytowy', 30, 10, 'Lasery D'),
       ('Laseroterapia', 'Rubinowy', 30, 10, 'Lasery C'),
       ('Laseroterapia', 'IPL', 30, 10, 'Lasery B'),
       ('Laseroterapia', 'Pulsacyjno-barwnikowy', 30, 10, 'Lasery D'),
       ('Laseroterapia', 'CO2', 30, 10, 'Lasery A'),
       ('Laseroterapia', 'Er-Yag', 30, 10, 'Lasery C'),
       ('Magnetoterapia', 'Terapuls', 45, 15, 'Pole magnetyczne A'),
       ('Magnetoterapia', 'Curapuls', 45, 15, 'Pole magnetyczne A'),
       ('Magnetoterapia', 'Megatronic', 45, 15, 'Pole magnetyczne A'),
       ('Magnetoterapia', 'Alfatron', 45, 15, 'Pole magnetyczne B'),
       ('Elektroterapia', 'Interdym', 30, 17, 'Elektroterapia A'),
       ('Elektroterapia', 'Interdynamic', 30, 17, 'Elektroterapia A'),
       ('Elektroterapia', 'Galwanizacja', 30, 17, 'Elektroterapia C'),
       ('Elektroterapia', 'Jonosfereza', 30, 17, 'Elektroterapia B'),
       ('Elektroterapia', 'Elektrostymulacja', 30, 17, 'Elektroterapia C'),
       ('Ultradźwięki', 'Ultradźwięki', 30, 7, 'Ultradźwięki'),
       ('Gimnastyka indywidualna', 'Staw łokciowy', 75, 40, 'Gimnastyka C'),
       ('Gimnastyka indywidualna', 'Staw kolanowy', 75, 40, 'Gimnastyka C'),
       ('Gimnastyka indywidualna', 'Staw barkowy', 75, 40, 'Gimnastyka B'),
       ('Gimnastyka indywidualna', 'Staw skokowy', 75, 40, 'Gimnastyka A'),
       ('Gimnastyka indywidualna', 'Nadgarstek', 75, 40, 'Gimnastyka A'),
       ('Gimnastyka indywidualna', 'Szyja', 75, 40, 'Gimnastyka D'),
       ('Gimnastyka indywidualna', 'Staw biodrowy', 75, 40, 'Gimnastyka B'),
       ('Gimnastyka indywidualna', 'Paliczki', 75, 40, 'Gimnastyka B'),
       ('Gimnastyka indywidualna', 'Klatka piersiowa', 75, 40, 'Gimnastyka D'),
       ('Gimnastyka ogólnousprawniająca', 'Gimnastyka ogólnousprawniająca', 75, 55, 'Gimnastyka A'),
       ('Gimnastyka ogólnousprawniająca', 'Gimnastyka ogólnousprawniająca', 105, 65, 'Gimnastyka A'),
       ('Gimnastyka ogólnousprawniająca', 'Gimnastyka ogólnousprawniająca', 135, 75, 'Gimnastyka A'),
       ('Aquavibron', 'Aquavibron', 30, 20, 'Fizjoterapia A'),
       ('Masaż wirowy', 'Stopy', 75, 12, 'Masaż mechaniczny'),
       ('Masaż wirowy', 'Dłonie', 75, 12, 'Masaż mechaniczny'),
       ('Krioterapia', 'Staw łokciowy', 30, 11, 'Krioterapia C'),
       ('Krioterapia', 'Staw kolanowy', 30, 11, 'Krioterapia C'),
       ('Krioterapia', 'Staw barkowy', 30, 11, 'Krioterapia B'),
       ('Krioterapia', 'Staw skokowy', 30, 11, 'Krioterapia A'),
       ('Krioterapia', 'Nadgarstek', 30, 11, 'Krioterapia A'),
       ('Krioterapia', 'Szyja', 30, 11, 'Krioterapia C'),
       ('Krioterapia', 'Staw biodrowy', 30, 11, 'Krioterapia B'),
       ('Krioterapia', 'Paliczki', 30, 11, 'Krioterapia B'),
       ('Lampa sollux', 'Czerwony filtr', 30, 17, 'Lampy A'),
        ('Lampa sollux', 'Niebieska filtr', 30, 7, 'Lampy A'),
       ('Gimnastyka korekcyjna', 'Dziecko', 75, 35, 'Gimnastyka dziecko'),
       ('Gimnastyka korekcyjna', 'Młodzież', 75, 35, 'Gimnastyka dorośli'),
       ('Gimnastyka korekcyjna', 'Młodzież', 105, 45, 'Gimnastyka dorośli'),
       ('Gimnastyka korekcyjna', 'Młodzież', 135, 55, 'Gimnastyka dorośli'),
       ('Gimnastyka korekcyjna', 'Dorosły', 75, 35, 'Gimnastyka dorośli'),
       ('Gimnastyka korekcyjna', 'Dorosły', 105, 45, 'Gimnastyka dorośli'),
       ('Gimnastyka korekcyjna', 'Dorosły', 135, 55, 'Gimnastyka dorośli'),
       ('Gimnastyka grupowa', '6 osób', 75, 15, 'Gimnastyka grupy'),
       ('Gimnastyka grupowa', '10 osób', 75, 12, 'Gimnastyka grupy'),
       ('Gimnastyka grupowa', '14 osób', 75, 10, 'Gimnastyka grupy'),
       ('Akupunktura', 'Plecy', 90, 100, 'Akupunktura A'),
       ('Akupunktura', 'Kark', 90, 100, 'Akupunktura C'),
       ('Akupunktura', 'Staw kolanowy', 90, 100, 'Akupunktura B'),
       ('Akupunktura', 'Głowa', 90, 100, 'Akupunktura D'),
       ('Akupunktura', 'Łokieć', 90, 100, 'Akupunktura B'),
       ('Akupunktura', 'Klatka piersiowa', 90, 100, 'Akupunktura C'),
       ('Spa', 'Czekolada', 105, 120, 'Masaż relaksacyjny A'),
       ('Spa', 'Masaż tajski', 105, 100, 'Masaż relaksacyjny B'),
       ('Spa', 'Świece', 105, 80, 'Masaż relaksacyjny B'),
       ('Spa', 'Gorący wosk', 105, 90, 'Masaż relaksacyjny C'),
       ('Spa', 'Usuwanie celluitu', 105, 70, 'Masaż relaksacyjny A'),
       ('Spa', 'Bambus', 105, 65, 'Masaż relaksacyjny B'),
       ('Kinesiotaping', 'Staw łokciowy', 30, 50, 'Kinesiotaping C'),
       ('Kinesiotaping', 'Staw kolanowy', 30, 50, 'Kinesiotaping C'),
       ('Kinesiotaping', 'Staw barkowy', 30, 50, 'Kinesiotaping B'),
       ('Kinesiotaping', 'Staw skokowy', 30, 50, 'Kinesiotaping A'),
       ('Kinesiotaping', 'Nadgarstek', 30, 50, 'Kinesiotaping A'),
       ('Kinesiotaping', 'Szyja', 30, 50, 'Kinesiotaping C'),
       ('Kinesiotaping', 'Staw biodrowy', 30, 50, 'Kinesiotaping B'),
       ('Kinesiotaping', 'Paliczki', 30, 50, 'Kinesiotaping A'),
       ('Kinesiotaping', 'Klatka piersiowa', 30, 50, 'Kinesiotaping B'),
       ('Masaż kobiety w ciąży', 'Masaż kobiety w ciąży', 60, 70, 'Masaż kobiet'),
       ('Drenaż limfatyczny', 'Ciało', 75, 85, 'Drenaż A'),
       ('Drenaż limfatyczny', 'Twarz', 75, 75, 'Drenaż B'),
       ('Masaż klasyczny', 'Plecy', 90, 80, 'Masaż klasyczny B'),
       ('Masaż klasyczny', 'Nogi', 90, 80, 'Masaż klasyczny A'),
       ('Masaż klasyczny', 'Ręce', 90, 80, 'Masaż klasyczny A'),
       ('Masaż klasyczny', 'Klatka piersiowa', 90, 80, 'Masaż klasyczny C'),
       ('Masaż klasyczny', 'Pośladki', 90, 80, 'Masaż klasyczny B');



DROP PROCEDURE IF EXISTS dodaj_stanowiska;
ALTER TABLE stanowiska
  AUTO_INCREMENT = 1;
DELIMITER //
CREATE PROCEDURE dodaj_stanowiska()
BEGIN
  DECLARE i INT DEFAULT 0; #iterator po ilosci
  WHILE i < 10 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery', 2);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 8 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery', 4);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 3 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery', 10);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 10 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora', 2);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 8 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora', 4);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 3 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora', 10);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 10 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora', 2);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 8 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora', 4);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 3 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora', 10);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 15 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Ultradźwięki komora', 2);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 4 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna', 15);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 7 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna', 10);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 10 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna', 6);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 16 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna', 2);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 20 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Aquavibron', 1);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 25 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Wirówka', 1);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 17 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Kriokomora', 4);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 13 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Kriokomora', 8);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 30 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Lampy', 1);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 15 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Akupunktura', 1);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 20 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka spa', 1);
  SET i = i + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 40 DO
  INSERT INTO stanowiska (nazwa, max_ilosc_osob) VALUES ('Łóżko do masażu', 1);
  SET i = i + 1;
  END WHILE;

END//
DELIMITER ;

DROP PROCEDURE IF EXISTS uzupelnianie_dostep_do_stanowiska;
DELIMITER //
CREATE PROCEDURE uzupelnianie_dostep_do_stanowiska()
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE iterator INT DEFAULT 1;

  WHILE i < 21 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Lasery A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 21 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Pole magnetyczne A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 21 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Elektroterapia A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 15 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Ultradźwięki');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 37 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Gimnastyka A');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Gimnastyka dziecko');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Gimnastyka dorośli');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Gimnastyka grupy');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 20 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Fizjoterapia A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 25 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Masaż mechaniczny');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 30 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Krioterapia A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 30 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Lampy A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 15 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Akupunktura A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 20 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Masaż relaksacyjny A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

  SET i = 0;
  WHILE i < 40 DO
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Kinesiotaping A');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Drenaż A');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Masaż klasyczny A');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Masaż kobiet');
  INSERT INTO dostep_do_stanowiska (stanowisko, wymagane_uprawnienia) VALUES (iterator, 'Akupunktura A');
  SET i = i + 1;
  SET iterator = iterator + 1;
  END WHILE;

END //
DELIMITER ;

DROP PROCEDURE IF EXISTS dodaj_uzytkownika_i_stan_konta;
DELIMITER //
CREATE PROCEDURE dodaj_uzytkownika_i_stan_konta(IN ilosc INT, IN iloscPracownikow INT) #ilosc klientów = ilosc - iloscPracownikow - 1 (bo prezez)
BEGIN
  DECLARE i INT DEFAULT 0; #iterator po ilosci
  DECLARE j INT DEFAULT 0; #iterator po peselach w tym samym dniu
  DECLARE tesamedaty INT; #zmienna losowa odpowiasajaca za
  DECLARE rozmedaty INT DEFAULT 0; #diffeerent date
  DECLARE mindata DATE DEFAULT '2010-12-31'; #urodziny najmłodsej osoby
  DECLARE data DATE;
  DECLARE peselbezkontrolnej CHAR(10);
  DECLARE pesel CHAR(11);
  DECLARE zmienna_losowa_1 INT;
  DECLARE uzytkwnik VARCHAR(15);

  WHILE i < ilosc DO #petla po ilosci
  SET j = 1;
  SET data = DATE_SUB(mindata, INTERVAL rozmedaty DAY);
  SET tesamedaty = FLOOR(RAND() * 400 + 1);
  WHILE j < tesamedaty AND i < ilosc DO #petla po urodzonych w tym samym dniu
  SET peselbezkontrolnej = CONCAT(
      SUBSTRING(YEAR(data), 3, 2),
      IF(YEAR(data) < 2000,
         LPAD(MONTH(data), 2, '0'),
         LPAD(MONTH(data) + 20, 2, '0')),
      LPAD(DAYOFMONTH(data), 2, '0'),
      LPAD(9999 - j, 4, '0')
    );
  SET pesel = CONCAT(peselbezkontrolnej,
                     MOD(9 * CAST(SUBSTRING(peselbezkontrolnej, 1, 1) AS UNSIGNED) +
                         7 * CAST(SUBSTRING(peselbezkontrolnej, 2, 1) AS UNSIGNED) +
                         3 * CAST(SUBSTRING(peselbezkontrolnej, 3, 1) AS UNSIGNED) +
                         1 * CAST(SUBSTRING(peselbezkontrolnej, 4, 1) AS UNSIGNED) +
                         9 * CAST(SUBSTRING(peselbezkontrolnej, 5, 1) AS UNSIGNED) +
                         7 * CAST(SUBSTRING(peselbezkontrolnej, 6, 1) AS UNSIGNED) +
                         3 * CAST(SUBSTRING(peselbezkontrolnej, 7, 1) AS UNSIGNED) +
                         1 * CAST(SUBSTRING(peselbezkontrolnej, 8, 1) AS UNSIGNED) +
                         9 * CAST(SUBSTRING(peselbezkontrolnej, 9, 1) AS UNSIGNED) +
                         7 * CAST(SUBSTRING(peselbezkontrolnej, 10, 1) AS UNSIGNED),
                         10));

  SET zmienna_losowa_1 = FLOOR(RAND() * 3000 + 1);

  IF i < iloscPracownikow THEN
    SET uzytkwnik = 'Pracownik';
  ELSEIF i = ilosc - 1 THEN
    SET uzytkwnik = 'Prezes';
  ELSE
    SET uzytkwnik = 'Klient';
  END IF;

  INSERT INTO uzytkownicy (PESEL, imie, nazwisko, data_dolaczenia, rola)
  VALUES (pesel,
          ELT(zmienna_losowa_1 % 624 + 1, 'Ada', 'Adalbert', 'Adam', 'Adela', 'Adelajda', 'Adrian', 'Aga', 'Agata',
              'Agnieszka', 'Albert', 'Alberta', 'Aldona', 'Aleksander', 'Aleksandra', 'Alfred', 'Alicja', 'Alina',
              'Amadeusz', 'Ambroży', 'Amelia', 'Anastazja', 'Anastazy', 'Anatol', 'Andrzej', 'Aneta', 'Angelika',
              'Angelina', 'Aniela', 'Anita', 'Anna', 'Antoni', 'Antonina', 'Anzelm', 'Apolinary', 'Apollo', 'Apolonia',
              'Apoloniusz', 'Ariadna', 'Arkadiusz', 'Arkady', 'Arlena', 'Arleta', 'Arletta', 'Arnold', 'Arnolf',
              'August', 'Augustyna', 'Aurela', 'Aurelia', 'Aurelian', 'Aureliusz', 'Balbina', 'Baltazar', 'Barbara',
              'Bartłomiej', 'Bartosz', 'Bazyli', 'Beata', 'Benedykt', 'Benedykta', 'Beniamin', 'Bernadeta', 'Bernard',
              'Bernardeta', 'Bernardyn', 'Bernardyna', 'Błażej', 'Bogdan', 'Bogdana', 'Bogna', 'Bogumił', 'Bogumiła',
              'Bogusław', 'Bogusława', 'Bohdan', 'Bolesław', 'Bonawentura', 'Bożena', 'Bronisław', 'Broniszław',
              'Bronisława', 'Brunon', 'Brygida', 'Cecyl', 'Cecylia', 'Celestyn', 'Celestyna', 'Celina', 'Cezary',
              'Cyprian', 'Cyryl', 'Dalia', 'Damian', 'Daniel', 'Daniela', 'Danuta', 'Daria', 'Dariusz', 'Dawid',
              'Diana', 'Dianna', 'Dobrawa', 'Dominik', 'Dominika', 'Donata', 'Dorian', 'Dorota', 'Dymitr', 'Edmund',
              'Edward', 'Edwin', 'Edyta', 'Egon', 'Eleonora', 'Eliasz', 'Eligiusz', 'Eliza', 'Elwira', 'Elżbieta',
              'Emanuel', 'Emanuela', 'Emil', 'Emilia', 'Emilian', 'Emiliana', 'Ernest', 'Ernestyna', 'Erwin', 'Erwina',
              'Eryk', 'Eryka', 'Eugenia', 'Eugeniusz', 'Eulalia', 'Eustachy', 'Ewelina', 'Fabian', 'Faustyn',
              'Faustyna', 'Felicja', 'Felicjan', 'Felicyta', 'Feliks', 'Ferdynand', 'Filip', 'Franciszek', 'Salezy',
              'Franciszka', 'Fryderyk', 'Fryderyka', 'Gabriel', 'Gabriela', 'Gaweł', 'Genowefa', 'Gerard', 'Gerarda',
              'Gerhard', 'Gertruda', 'Gerwazy', 'Godfryd', 'Gracja', 'Gracjan', 'Grażyna', 'Greta', 'Grzegorz',
              'Gustaw', 'Gustawa', 'Gwidon', 'Halina', 'Hanna', 'Helena', 'Henryk', 'Henryka', 'Herbert', 'Hieronim',
              'Hilary', 'Hipolit', 'Honorata', 'Hubert', 'Ida', 'Idalia', 'Idzi', 'Iga', 'Ignacy', 'Igor', 'Ildefons',
              'Ilona', 'Inga', 'Ingeborga', 'Irena', 'Ireneusz', 'Irma', 'Irmina', 'Irwin', 'Ismena', 'Iwo', 'Iwona',
              'Izabela', 'Izolda', 'Izyda', 'Izydor', 'Jacek', 'Jadwiga', 'Jagoda', 'Jakub', 'Jan', 'Janina', 'January',
              'Janusz', 'Jarema', 'Jarogniew', 'Jaromir', 'Jarosław', 'Jarosława', 'Jeremi', 'Jeremiasz', 'Jerzy',
              'Jędrzej', 'Joachim', 'Joanna', 'Jolanta', 'Jonasz', 'Jonatan', 'Jowita', 'Józef', 'Józefa', 'Józefina',
              'Judyta', 'Julia', 'Julian', 'Julianna', 'Julita', 'Juliusz', 'Justyn', 'Justyna', 'Kacper', 'Kaja',
              'Kajetan', 'Kalina', 'Kamil', 'Kamila', 'Karina', 'Karol', 'Karolina', 'Kasper', 'Katarzyna', 'Kazimiera',
              'Kazimierz', 'Kinga', 'Klara', 'Klarysa', 'Klaudia', 'Klaudiusz', 'Klaudyna', 'Klemens', 'Klementyn',
              'Klementyna', 'Kleopatra', 'Klotylda', 'Konrad', 'Konrada', 'Konstancja', 'Konstanty', 'Konstantyn',
              'Kordelia', 'Kordian', 'Kordula', 'Kornel', 'Kornelia', 'Kryspin', 'Krystian', 'Krystyn', 'Krystyna',
              'Krzysztof', 'Ksenia', 'Kunegunda', 'Laura', 'Laurenty', 'Laurentyn', 'Laurentyna', 'Lech', 'Lechosław',
              'Lechosława', 'Leokadia', 'Leon', 'Leonard', 'Leonarda', 'Leonia', 'Leopold', 'Leopoldyna', 'Lesław',
              'Lesława', 'Leszek', 'Lidia', 'Ligia', 'Lilian', 'Liliana', 'Lilianna', 'Lilla', 'Liwia', 'Liwiusz',
              'Liza', 'Lolita', 'Longin', 'Loretta', 'Luba', 'Lubomir', 'Lubomira', 'Lucja', 'Lucjan', 'Lucjusz',
              'Lucyna', 'Ludmiła', 'Ludomił', 'Ludomir', 'Ludosław', 'Ludwik', 'Ludwika', 'Ludwina', 'Luiza',
              'Lukrecja', 'Lutosław', 'Łucja', 'Łucjan', 'Łukasz', 'Maciej', 'Madlena', 'Magda', 'Magdalena', 'Makary',
              'Maksym', 'Maksymilian', 'Malina', 'Malwin', 'Malwina', 'Małgorzata', 'Manfred', 'Manfreda', 'Manuela',
              'Marcel', 'Marcela', 'Marceli', 'Marcelina', 'Marcin', 'Marcjan', 'Marcjanna', 'Marcjusz', 'Marek',
              'Margareta', 'Maria', 'MariaMagdalena', 'Marian', 'Marianna', 'Marietta', 'Marina', 'Mariola', 'Mariusz',
              'Marlena', 'Marta', 'Martyna', 'Maryla', 'Maryna', 'Marzanna', 'Marzena', 'Mateusz', 'Matylda', 'Maurycy',
              'Melania', 'Melchior', 'Metody', 'Michalina', 'Michał', 'Mieczysław', 'Mieczysława', 'Mieszko', 'Mikołaj',
              'Milena', 'Miła', 'Miłosz', 'Miłowan', 'Miłowit', 'Mira', 'Mirabella', 'Mirella', 'Miron', 'Mirosław',
              'Mirosława', 'Modest', 'Monika', 'Nadia', 'Nadzieja', 'Napoleon', 'Narcyz', 'Narcyza', 'Nastazja',
              'Natalia', 'Natasza', 'Nikita', 'Nikodem', 'Nina', 'Nora', 'Norbert', 'Norberta', 'Norma', 'Norman',
              'Oda', 'Odila', 'Odon', 'Ofelia', 'Oksana', 'Oktawia', 'Oktawian', 'Olaf', 'Oleg', 'Olga', 'Olgierd',
              'Olimpia', 'Oliwia', 'Oliwier', 'Onufry', 'Orfeusz', 'Oskar', 'Otto', 'Otylia', 'Pankracy', 'Parys',
              'Patrycja', 'Patrycy', 'Patryk', 'Paula', 'Paulina', 'Paweł', 'Pelagia', 'Petronela', 'Petronia',
              'Petroniusz', 'Piotr', 'Pola', 'Polikarp', 'Protazy', 'Przemysław', 'Radomił', 'Radomiła', 'Radomir',
              'Radosław', 'Radosława', 'Radzimir', 'Rafael', 'Rafaela', 'Rafał', 'Rajmund', 'Rajmunda', 'Rajnold',
              'Rebeka', 'Regina', 'Remigiusz', 'Rena', 'Renata', 'Robert', 'Roberta', 'Roch', 'Roderyk', 'Rodryg',
              'Rodryk', 'Roger', 'Roksana', 'Roland', 'Roma', 'Roman', 'Romana', 'Romeo', 'Romuald', 'Rozalia',
              'Rozanna', 'Róża', 'Rudolf', 'Rudolfa', 'Rudolfina', 'Rufin', 'Rupert', 'Ryszard', 'Ryszarda', 'Sabina',
              'Salomea', 'Salomon', 'Samuel', 'Samuela', 'Sandra', 'Sara', 'Sawa', 'Sebastian', 'Serafin', 'Sergiusz',
              'Sewer', 'Seweryn', 'Seweryna', 'Sędzisław', 'Sędziwoj', 'Siemowit', 'Sława', 'Sławomir', 'Sławomira',
              'Sławosz', 'Sobiesław', 'Sobiesława', 'Sofia', 'Sonia', 'Stanisław', 'Stanisława', 'Stefan', 'Stefania',
              'Sulimiera', 'Sulimierz', 'Sulimir', 'Sydonia', 'Sykstus', 'Sylwan', 'Sylwana', 'Sylwester', 'Sylwia',
              'Sylwiusz', 'Symeon', 'Szczepan', 'Szczęsna', 'Szczęsny', 'Szymon', 'Ścibor', 'Świętopełk', 'Tadeusz',
              'Tamara', 'Tatiana', 'Tekla', 'Telimena', 'Teodor', 'Teodora', 'Teodozja', 'Teodozjusz', 'Teofil',
              'Teofila', 'Teresa', 'Tobiasz', 'Toma', 'Tomasz', 'Tristan', 'Trojan', 'Tycjan', 'Tymon', 'Tymoteusz',
              'Tytus', 'Unisław', 'Ursyn', 'Urszula', 'Violetta', 'Wacław', 'Wacława', 'Waldemar', 'Walenty',
              'Walentyna', 'Waleria', 'Walerian', 'Waleriana', 'Walery', 'Walter', 'Wanda', 'Wasyl', 'Wawrzyniec',
              'Wera', 'Werner', 'Weronika', 'Wieńczysła', 'Wiesław', 'Wiesława', 'Wiktor', 'Wiktoria', 'Wilhelm',
              'Wilhelmina', 'Wilma', 'Wincenta', 'Wincenty', 'Wińczysła', 'Wiola', 'Wioletta', 'Wirgiliusz', 'Wirginia',
              'Wirginiusz', 'Wisław', 'Wisława', 'Wit', 'Witalis', 'Witold', 'Witolda', 'Witołd', 'Witomir', 'Wiwanna',
              'Władysława', 'Władysław', 'Włodzimierz', 'Włodzimir', 'Wodzisław', 'Wojciech', 'Wojciecha', 'Zachariasz',
              'Zbigniew', 'Zbysław', 'Zbyszko', 'Zdobysław', 'Zdzisław', 'Zdzisława', 'Zenobia', 'Zenobiusz', 'Zenon',
              'Zenona', 'Ziemowit', 'Zofia', 'Zula', 'Zuzanna', 'Zygfryd', 'Zygmunt', 'Zyta', 'Żaklina', 'Żaneta',
              'Żanna', 'Żelisław', 'Żytomir'),
          ELT(zmienna_losowa_1 % 94 + 1, 'Nowak', 'Kowalski', 'Wiśniewski', 'Dąbrowski', 'Lewandowski', 'Wójcik',
              'Kamiński', 'Kowalczyk', 'Zieliński', 'Szymański', 'Woźniak', 'Kozłowski', 'Jankowski', 'Wojciechowski',
              'Kwiatkowski', 'Kaczmarek', 'Mazur', 'Krawczyk', 'Piotrowski', 'Grabowski', 'Nowakowski', 'Pawłowski',
              'Michalski', 'Nowicki', 'Adamczyk', 'Dudek', 'Zając', 'Wieczorek', 'Jabłoński', 'Król', 'Majewski',
              'Olszewski', 'Jaworski', 'Wróbel', 'Malinowski', 'Pawlak', 'Witkowski', 'Walczak', 'Stępień', 'Górski',
              'Rutkowski', 'Michalak', 'Sikora', 'Ostrowski', 'Baran', 'Duda', 'Szewczyk', 'Tomaszewski', 'Pietrzak',
              'Marciniak', 'Wróblewski', 'Zalewski', 'Jakubowski', 'Jasiński', 'Zawadzki', 'Sadowski', 'Bąk',
              'Chmielewski', 'Włodarczyk', 'Borkowski', 'Czarnecki', 'Sawicki', 'Sokołowski', 'Urbański', 'Kubiak',
              'Maciejewski', 'Szczepański', 'Kucharski', 'Wilk', 'Kalinowski', 'Lis', 'Mazurek', 'Wysocki', 'Adamski',
              'Kaźmierczak', 'Wasilewski', 'Sobczak', 'Czerwiński', 'Andrzejewski', 'Cieślak', 'Głowacki', 'Zakrzewski',
              'Kołodziej', 'Sikorski', 'Krajewski', 'Gajewski', 'Szymczak', 'Szulc', 'Baranowski', 'Laskowski',
              'Brzeziński', 'Makowski', 'Ziółkowski', 'Przybylski'),
          DATE_SUB(CURRENT_DATE, INTERVAL (zmienna_losowa_1) DAY),
          uzytkwnik);

  IF uzytkwnik <> 'Pracownik' THEN
    INSERT INTO stan_konta(uzytkownik, saldo)
      VALUE (pesel, zmienna_losowa_1 % 200 + j);
  ELSE
    INSERT INTO specjalizacje (pracownik, uprawnienia, pensja)
    VALUES (pesel,
            (SELECT nazwa FROM uprawnienia WHERE nr = zmienna_losowa_1 % 39 + 1),
            zmienna_losowa_1 + 2000);
  END IF;


  SET i = i + 1;
  SET j = j + 1;
  END WHILE;
  SET rozmedaty = rozmedaty + zmienna_losowa_1 % 150 + 1;
  END WHILE;
END//
DELIMITER ;


#################################################################################


# założenie przy generowaniu - jest baaaardzo dużo klientów

DELETE
FROM zabiegi
WHERE TRUE;

DELETE
FROM transakcje
WHERE TRUE;

# ALTER TABLE konto_kliniki
#   MODIFY stan_konta BIGINT NOT NULL;

# założenie przy generowaniu - jest baaaardzo dużo klientów

DROP PROCEDURE IF EXISTS uzupelnianie_zabiegow;
ALTER TABLE zabiegi
  AUTO_INCREMENT = 1;
DELIMITER //
CREATE PROCEDURE uzupelnianie_zabiegow(IN poczatek DATE, IN koniec DATE)
BEGIN
  DECLARE iterator INT DEFAULT 0; # przyda się przy generowaniu klientów do zabiegów
  DECLARE iterator_klientow INT DEFAULT 0; # na jego podstawie będziemy iterować klientów
  DECLARE iterator_godziny TIME; # na jego podstawie będziemy iterować godziny
  DECLARE iterator_dni DATE DEFAULT poczatek; # na jego podstawie będziemy iterować dni i ustalać godziny pracy
  DECLARE iterator_sekwencji INT DEFAULT 0; # na jego podstawie jest iterowana sekwancja dodawania zabiegów
  DECLARE warunek_petli BOOLEAN;
  DECLARE pomoc_godziny TIME;
  DECLARE wylosowane_stanowisko_id INT DEFAULT 0; # id wylosowanego stanowiska
  DECLARE wylosowane_stanowisko_nazwa VARCHAR(45);
  DECLARE dlugosc_sekwencji INT DEFAULT 0;
  DECLARE ilosc_osob_na_stanowisko INT DEFAULT 0;
  DECLARE ilosc_pasujacych_uslug INT DEFAULT 0;
  DECLARE wylosowana_usluga INT DEFAULT 0;
  DECLARE wylosowana_usluga_id INT DEFAULT 0;
  DECLARE wylosowana_usluga_naleznosc INT DEFAULT 0;
  DECLARE pesel_menagera CHAR(11);
  DECLARE obecny_klient CHAR(11);
  DECLARE obecny_pracownik CHAR(11);
  DECLARE uprawnienia_pracownika VARCHAR(45);
  DECLARE grupa_pracownika VARCHAR(45);
  DECLARE ilosc_klientow INT;
  DECLARE koniec_pracownikow BOOLEAN DEFAULT FALSE;
#   DECLARE zmienna_pomoc INT DEFAULT 0;
  DECLARE calkowita_kwota_za_zabiegi INT DEFAULT 0;
  DECLARE kursor_pracownicy CURSOR FOR
    SELECT PESEL
    FROM uzytkownicy
    WHERE rola LIKE 'Pracownik';
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
      SET koniec_pracownikow = TRUE;
#       SELECT 'handler';
    END;

  DROP TABLE IF EXISTS sekwencja_dodawania;
  CREATE TABLE sekwencja_dodawania
  (
    ID        INT PRIMARY KEY AUTO_INCREMENT,
    nazwa     VARCHAR(30),
    czas      TIME,
    pora_dnia INT COMMENT '0 - rano i wieczorem, 1 - rano, 2 - wieczorem'
  );
  ALTER TABLE sekwencja_dodawania
    AUTO_INCREMENT = 1;
  INSERT INTO sekwencja_dodawania (nazwa, czas, pora_dnia)
  VALUES ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Lasery', '00:30:00', 0),
         ('Magnetokomora', '00:45:00', 0),
         ('Magnetokomora', '00:45:00', 0),
         ('Magnetokomora', '00:45:00', 0),
         ('Magnetokomora', '00:45:00', 0),
         ('Magnetokomora', '00:45:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Elektrokomora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Ultradźwięki komora', '00:30:00', 0),
         ('Salka gimnastyczna', '01:15:00', 0),
         ('Salka gimnastyczna', '02:15:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Aquavibron', '00:30:00', 0),
         ('Wirówka', '01:15:00', 0),
         ('Wirówka', '01:15:00', 0),
         ('Wirówka', '01:15:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Kriokomora', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Lampy', '00:30:00', 0),
         ('Akupunktura', '01:30:00', 0),
         ('Akupunktura', '01:30:00', 0),
         ('Salka spa', '01:30:00', 0),
         ('Salka spa', '01:30:00', 0),
         ('Łóżko do masażu', '01:15:00', 0),
         ('Łóżko do masażu', '01:15:00', 0),
         ('Łóżko do masażu', '01:30:00', 0);

  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Prezes'
  LIMIT 1
    INTO pesel_menagera;


  DROP TABLE IF EXISTS stanowiska_pomoc; # tablica z której będę usuwał używane stanowiska
  CREATE TABLE stanowiska_pomoc
  (
    ID             INT,
    nazwa          VARCHAR(45),
    max_ilosc_osob INT
  );

  DROP TEMPORARY TABLE IF EXISTS pracownicy_tablica;
  CREATE TEMPORARY TABLE pracownicy_tablica
  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Pracownik';

  DROP TEMPORARY TABLE IF EXISTS klienci_tablica;
  CREATE TEMPORARY TABLE klienci_tablica
  SELECT PESEL
  FROM uzytkownicy
  WHERE rola LIKE 'Klient';

  SELECT count(PESEL)
  FROM klienci_tablica
  LIMIT 1 INTO ilosc_klientow;

#   DROP TABLE IF EXISTS pomoc;
#   CREATE TABLE pomoc
#   (
#     pesel CHAR(11)
#   );

  # Tutaj moge też dorzucić, czy ten pesel podany jest rzeczywiście peselem prezesa i jak nie, to signalem rzucic.


  ######################################################################################################################

  WHILE iterator_dni <= koniec DO # przechodzę po wszystkich datach

  # wypełniam tabelę dostępnymi stanowiskami
  DELETE FROM stanowiska_pomoc WHERE TRUE;
  INSERT INTO stanowiska_pomoc (ID, nazwa, max_ilosc_osob)
  SELECT *
  FROM stanowiska;

  SET koniec_pracownikow = FALSE;
  OPEN kursor_pracownicy;
  FETCH kursor_pracownicy INTO obecny_pracownik;
  SET iterator_klientow = 0;
#   SET zmienna_pomoc = 0;
  WHILE koniec_pracownikow = FALSE DO
  SET wylosowane_stanowisko_id = -1;


  SELECT uprawnienia.nazwa, uprawnienia.grupa
  FROM pracownicy_tablica
         JOIN specjalizacje ON pracownicy_tablica.PESEL LIKE specjalizacje.pracownik
         JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  WHERE pracownicy_tablica.PESEL LIKE obecny_pracownik
  LIMIT 1
    INTO uprawnienia_pracownika, grupa_pracownika;

  # zmienić na counta i zmienić warunek w if niżej


  SELECT stanowiska_pomoc.ID, stanowiska_pomoc.max_ilosc_osob, stanowiska_pomoc.nazwa
  FROM stanowiska_pomoc
         JOIN dostep_do_stanowiska ON stanowiska_pomoc.ID = dostep_do_stanowiska.stanowisko
         JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  WHERE uprawnienia.nazwa <= uprawnienia_pracownika
    AND uprawnienia.grupa = grupa_pracownika
  LIMIT 1
    INTO wylosowane_stanowisko_id, ilosc_osob_na_stanowisko, wylosowane_stanowisko_nazwa;

  #           SELECT wylosowane_stanowisko_id;


  IF wylosowane_stanowisko_id > 0 THEN # sprawdzam, czy jest jeszcze jakieś wolne stanowisko



    IF ilosc_osob_na_stanowisko > 2 THEN
      SET ilosc_osob_na_stanowisko =
          ilosc_osob_na_stanowisko - MOD(wylosowane_stanowisko_id, 2); # ustalanie ile jest miejsc wolnych
    END IF ;

    DELETE FROM stanowiska_pomoc WHERE ID = wylosowane_stanowisko_id; # usuwanie użytego stanowiska

    SELECT count(*) # wyliczanie jak dluga jest sekwencja danego rodzaju zabiegu
    FROM sekwencja_dodawania
    WHERE pora_dnia = 0
      AND nazwa LIKE wylosowane_stanowisko_nazwa
    ORDER BY ID INTO dlugosc_sekwencji;


    SET iterator_sekwencji = 0;

    SELECT godzina_rozpoczecia # ustalanie godziny rozpoczęcia
    FROM godziny_otwarcia
    WHERE ID = dayofweek(iterator_dni)
    LIMIT 1
      INTO iterator_godziny;

    SET warunek_petli = TRUE;

    # jak wchodzi, to przynajmniej jeden obrót będzie zrobiony
    # przechodzi po wszystkich sekwencjach i odpowiednio losuje
    WHILE warunek_petli = TRUE DO # przebieganie po godzinach według odpowiedniej sekwencji

    # losowanie odpowiedniej usługi
    SET wylosowana_usluga = round(rand() * 100);

    SELECT count(uslugi_rehabilitacyjne.ID)
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika INTO ilosc_pasujacych_uslug;

    SET wylosowana_usluga = MOD(wylosowana_usluga, ilosc_pasujacych_uslug);

    SELECT uslugi_rehabilitacyjne.ID
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika
    LIMIT wylosowana_usluga, 1
      INTO wylosowana_usluga_id;

    SET wylosowana_usluga_naleznosc = 0;

    SELECT uslugi_rehabilitacyjne.cena
    FROM uslugi_rehabilitacyjne
    WHERE uslugi_rehabilitacyjne.ID = wylosowana_usluga_id
    LIMIT 1
      INTO wylosowana_usluga_naleznosc;

    # w tym momencie mam pracownika, datę, stanowiko

    SET iterator = 0;
#     SELECT ilosc_osob_na_stanowisko;
    WHILE iterator < ilosc_osob_na_stanowisko DO
    SELECT PESEL
    FROM klienci_tablica
    LIMIT iterator_klientow, 1
      INTO obecny_klient;

    # losowanie odpowiedniej usługi
    SET wylosowana_usluga = round(rand() * 100);

    SELECT count(uslugi_rehabilitacyjne.ID)
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika INTO ilosc_pasujacych_uslug;

    SET wylosowana_usluga = MOD(wylosowana_usluga, ilosc_pasujacych_uslug);

    SELECT uslugi_rehabilitacyjne.ID
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika
    LIMIT wylosowana_usluga, 1
      INTO wylosowana_usluga_id;

    SET wylosowana_usluga_naleznosc = 0;

    SELECT uslugi_rehabilitacyjne.cena
    FROM uslugi_rehabilitacyjne
    WHERE uslugi_rehabilitacyjne.ID = wylosowana_usluga_id
    LIMIT 1
      INTO wylosowana_usluga_naleznosc;


    # TODO usunąć to drugie dodawanie przy niesymetrycznym dodawaniu
    # dodanie tych zabiegów dwa razy, rano i wieczorem

    IF iterator_dni < date(now()) THEN
      INSERT INTO zabiegi (klient, pracownik, data_zabiegu, usluga, stanowisko, oplacono)
      VALUES (obecny_klient, obecny_pracownik, concat(iterator_dni, ' ', iterator_godziny), wylosowana_usluga_id,
              wylosowane_stanowisko_id, 'tak');
    ELSE

      INSERT INTO zabiegi (klient, pracownik, data_zabiegu, usluga, stanowisko, oplacono)
      VALUES (obecny_klient, obecny_pracownik, concat(iterator_dni, ' ', iterator_godziny), wylosowana_usluga_id,
              wylosowane_stanowisko_id, 'nie');
    END IF ;
#
#           INSERT INTO pomoc (pesel)
#     VALUES (obecny_pracownik);

    IF iterator_dni < date(now()) THEN
      INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
      VALUES (pesel_menagera, obecny_klient, iterator_dni, wylosowana_usluga_naleznosc, 'za_zabieg');

      SET calkowita_kwota_za_zabiegi = calkowita_kwota_za_zabiegi + wylosowana_usluga_naleznosc;
    END IF ;


    # losowanie odpowiedniej usługi
    SET wylosowana_usluga = round(rand() * 100);

    SELECT count(uslugi_rehabilitacyjne.ID)
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika INTO ilosc_pasujacych_uslug;

    SET wylosowana_usluga = MOD(wylosowana_usluga, ilosc_pasujacych_uslug);

    SELECT uslugi_rehabilitacyjne.ID
    FROM uslugi_rehabilitacyjne
           JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
    WHERE uprawnienia.grupa = grupa_pracownika
      AND uprawnienia.nazwa <= uprawnienia_pracownika
    LIMIT wylosowana_usluga, 1
      INTO wylosowana_usluga_id;

    SET wylosowana_usluga_naleznosc = 0;

    SELECT uslugi_rehabilitacyjne.cena
    FROM uslugi_rehabilitacyjne
    WHERE uslugi_rehabilitacyjne.ID = wylosowana_usluga_id
    LIMIT 1
      INTO wylosowana_usluga_naleznosc;

    IF iterator_dni < date(now()) THEN
      INSERT INTO zabiegi (klient, pracownik, data_zabiegu, usluga, stanowisko,oplacono)
      VALUES (obecny_klient, obecny_pracownik, concat(iterator_dni, ' ', addtime(iterator_godziny, '04:00:00')),
              wylosowana_usluga_id, wylosowane_stanowisko_id,'tak');
    ELSE
      INSERT INTO zabiegi (klient, pracownik, data_zabiegu, usluga, stanowisko,oplacono)
      VALUES (obecny_klient, obecny_pracownik, concat(iterator_dni, ' ', addtime(iterator_godziny, '04:00:00')),
              wylosowana_usluga_id, wylosowane_stanowisko_id,'nie');
    END IF ;

    IF iterator_dni < date(now()) THEN
      INSERT INTO transakcje (odbiorca, placacy, data, kwota, opis)
      VALUES (pesel_menagera, obecny_klient, iterator_dni, wylosowana_usluga_naleznosc, 'za_zabieg');
      SET calkowita_kwota_za_zabiegi = calkowita_kwota_za_zabiegi + wylosowana_usluga_naleznosc;
    END IF ;

    SET iterator = iterator + 1;
    SET iterator_klientow = iterator_klientow + 1;
    END WHILE ;

    SELECT czas # wyliczanie kiedy bedzie nastepny zabieg
    FROM sekwencja_dodawania
    WHERE pora_dnia <> 2
      AND nazwa LIKE wylosowane_stanowisko_nazwa
    ORDER BY ID
    LIMIT iterator_sekwencji, 1
      INTO pomoc_godziny;

    SET iterator_godziny = addtime(iterator_godziny, pomoc_godziny);
    SET iterator_sekwencji = iterator_sekwencji + 1;

    IF iterator_sekwencji = dlugosc_sekwencji THEN

      SET warunek_petli = FALSE;

    END IF ;
    END WHILE;

  END IF ;
  SET wylosowane_stanowisko_id = -1;
  FETCH kursor_pracownicy INTO obecny_pracownik;
  END WHILE ;
  CLOSE kursor_pracownicy;


  # TODO odkomentować w przypadku niesymetrycznego dodaawania oraz upeznić się, że się zmieniło pierwsze TODO
  #
  #     # wypełniam tabelę dostępnymi stanowiskami
  #     DELETE FROM stanowiska_pomoc WHERE TRUE;
  #     INSERT INTO stanowiska_pomoc (ID, nazwa, max_ilosc_osob)
  #     SELECT *
  #     FROM stanowiska;
  #
  #     SET koniec_pracownikow = FALSE;
  #     OPEN kursor_pracownicy;
  #     FETCH kursor_pracownicy INTO obecny_pracownik;
  #     SET iterator_klientow = 0;
  #   WHILE koniec_pracownikow = FALSE DO
  #     SET wylosowane_stanowisko_id = -1;
  # #    SET zmienna_pomoc = zmienna_pomoc + 1;
  #
  #
  #       SELECT uprawnienia.nazwa, uprawnienia.grupa
  #       FROM pracownicy_tablica
  #              JOIN specjalizacje ON pracownicy_tablica.PESEL LIKE specjalizacje.pracownik
  #              JOIN uprawnienia ON specjalizacje.uprawnienia = uprawnienia.nazwa
  #       WHERE pracownicy_tablica.PESEL LIKE obecny_pracownik
  #            LIMIT 1
  #       INTO uprawnienia_pracownika, grupa_pracownika;
  #
  #     # zmienić na counta i zmienić warunek w if niżej
  #
  #
  #       SELECT stanowiska_pomoc.ID, stanowiska_pomoc.max_ilosc_osob, stanowiska_pomoc.nazwa
  #       FROM stanowiska_pomoc
  #              JOIN dostep_do_stanowiska ON stanowiska_pomoc.ID = dostep_do_stanowiska.stanowisko
  #              JOIN uprawnienia ON dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
  #       WHERE uprawnienia.nazwa <= uprawnienia_pracownika
  #         AND uprawnienia.grupa = grupa_pracownika
  #       LIMIT 1
  #       INTO wylosowane_stanowisko_id, ilosc_osob_na_stanowisko, wylosowane_stanowisko_nazwa;
  #
  # #           SELECT wylosowane_stanowisko_id;
  #
  #
  #       IF wylosowane_stanowisko_id > 0 THEN # sprawdzam, czy jest jeszcze jakieś wolne stanowisko
  #
  #         SET ilosc_osob_na_stanowisko = ilosc_osob_na_stanowisko - MOD(wylosowane_stanowisko_id , 3); # ustalanie ile jest miejsc wolnych
  #
  #         DELETE FROM stanowiska_pomoc WHERE ID = wylosowane_stanowisko_id; # usuwanie użytego stanowiska
  #
  #         SELECT count(*) # wyliczanie jak dluga jest sekwencja danego rodzaju zabiegu
  #           FROM sekwencja_dodawania
  #             WHERE pora_dnia = 0  AND nazwa like wylosowane_stanowisko_nazwa
  #         ORDER BY ID
  #         INTO dlugosc_sekwencji;
  #
  #
  #         SET iterator_sekwencji = 0;
  #
  #         SET iterator_godziny = '12:00:00';
  #
  #         SET warunek_petli = TRUE;
  #
  #         # jak wchodzi, to przynajmniej jeden obrót będzie zrobiony
  #         # przechodzi po wszystkich sekwencjach i odpowiednio losuje
  #         WHILE warunek_petli = TRUE DO # przebieganie po godzinach według odpowiedniej sekwencji
  #
  #         # losowanie odpowiedniej usługi
  #         SET wylosowana_usluga = round(rand() * 100);
  #
  #         SELECT count(uslugi_rehabilitacyjne.ID)
  #         FROM uslugi_rehabilitacyjne
  #         JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
  #         WHERE uprawnienia.grupa = grupa_pracownika
  #         AND uprawnienia.nazwa <= uprawnienia_pracownika
  #         INTO ilosc_pasujacych_uslug;
  #
  #         SET wylosowana_usluga =  MOD(wylosowana_usluga, ilosc_pasujacych_uslug);
  #
  #         SELECT uslugi_rehabilitacyjne.ID
  #         FROM uslugi_rehabilitacyjne
  #         JOIN uprawnienia ON uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
  #         WHERE uprawnienia.grupa = grupa_pracownika
  #         AND uprawnienia.nazwa <= uprawnienia_pracownika
  #         LIMIT wylosowana_usluga, 1
  #         INTO wylosowana_usluga_id;
  #
  #         # w tym momencie mam pracownika, datę, stanowiko oraz usługę
  #
  #
  #           SET iterator = 0;
  #
  #           WHILE iterator < ilosc_osob_na_stanowisko DO
  #
  #             SELECT PESEL
  #             FROM klienci_tablica
  #             LIMIT iterator_klientow, 1
  #             INTO obecny_klient;
  #
  #             # TODO usunąć to drugie dodawanie przy niesymetrycznym dodawaniu
  #             # dodanie tych zabiegów dwa razy, rano i wieczorem
  #             INSERT INTO zabiegi (klient, pracownik, data_zabiegu, usluga, stanowisko)
  #             VALUES (obecny_klient, obecny_pracownik, concat(iterator_dni, ' ', iterator_godziny), wylosowana_usluga_id, wylosowane_stanowisko_id),
  #
  #
  #             SET iterator = iterator + 1;
  #             SET iterator_klientow = iterator_klientow + 1;
  #           END WHILE ;
  #
  #           SELECT czas # wyliczanie kiedy bedzie nastepny zabieg
  #           FROM sekwencja_dodawania
  #           WHERE pora_dnia <> 2
  #             AND nazwa LIKE wylosowane_stanowisko_nazwa
  #           ORDER BY ID
  #           LIMIT iterator_sekwencji, 1
  #             INTO pomoc_godziny;
  #
  #           SET iterator_godziny = addtime(iterator_godziny, pomoc_godziny);
  #           SET iterator_sekwencji = iterator_sekwencji + 1;
  #
  #           IF iterator_sekwencji = dlugosc_sekwencji THEN
  #
  #             SET warunek_petli = FALSE;
  #
  #           END IF ;
  #
  #         END WHILE;
  #
  #       END IF ;
  #       SET wylosowane_stanowisko_id = -1;
  #       FETCH kursor_pracownicy INTO obecny_pracownik;
  #
  #     END WHILE ;
  #     CLOSE kursor_pracownicy;

#   SELECT zmienna_pomoc;
  SET iterator_dni = ADDDATE(iterator_dni, INTERVAL 1 DAY);
  END WHILE;

  #  SELECT zmienna_pomoc;
  #TODO POTRZEBUJE PESEL MENAGERA
  UPDATE stan_konta
  SET stan_konta.saldo = stan_konta.saldo + calkowita_kwota_za_zabiegi
  WHERE uzytkownik = pesel_menagera;

  DROP TABLE IF EXISTS stanowiska_pomoc;
  DROP TABLE IF EXISTS sekwencja_dodawania;
  DROP TEMPORARY TABLE IF EXISTS klienci_tablica;
  DROP TEMPORARY TABLE IF EXISTS pracownicy_tablica;
END //
DELIMITER ;

CALL dodaj_stanowiska();
CALL uzupelnianie_dostep_do_stanowiska();
#CALL dodaj_uzytkownika_i_stan_konta(500, 10);
CALL dodaj_uzytkownika_i_stan_konta(50000, 2000);
CALL uzupelnianie_zabiegow(date_sub(date(now()), INTERVAL 2 DAY), date_add(date(now()), INTERVAL 3 DAY));
