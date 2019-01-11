create database Klinika default character set utf8mb4 collate utf8mb4_unicode_ci;

create table uzytkownicy
(
  PESEL           char(11)                               not null primary key,
  imie            varchar(30)                            not null,
  nazwisko        varchar(30)                            not null,
  data_dolaczenia date                                   not null,
  rola            enum ('Prezes', 'Pracownik', 'Klient') not null comment 'Trzy podstawowe rodzaje uzytkownikow.'
);

create table uprawnienia
(
  #ID    int         not null primary key auto_increment,
  nazwa varchar(45) not null primary key,
  grupa varcahr(45) not null
);

create table uslugi_rehabilitacyjne
(
  ID           int          not null primary key auto_increment,
  rodzaj       varchar(50)  not null,
  nazwa        varchar(100) not null,
  czas_trwania int          not null,
  cena         int          not null,
  uprawnienia  varchar(45)  not null,
  constraint uprawnieniaU
    foreign key (uprawnienia)
      references uprawnienia (nazwa)
      on update no action
      on delete no action
);

create table transakcje
(
  ID       int                                           not null primary key auto_increment,
  odbiorca char(11)                                      not null,
  constraint odbiorcaT
    foreign key (odbiorca)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  placacy  char(11)                                      not null,
  constraint placacyT
    foreign key (placacy)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  data     date                                          not null,
  kwota    int                                           not null,
  opis     enum ('pensja', 'za_zabieg', 'zwrot', 'inne') not null
);

create table stanowiska
(
  ID             int         not null primary key auto_increment,
  nazwa          varchar(45) not null,
  max_ilosc_osob int         not null
);

create table zabiegi
(
  ID           int      not null primary key auto_increment,
  klient       char(11) not null,
  constraint klientZ
    foreign key (klient)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  pracownik    char(11) not null,
  constraint pracownikZ
    foreign key (pracownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  data_zabiegu datetime not null,
  usluga       int      not null,
  constraint uslugaZ
    foreign key (usluga)
      references uslugi_rehabilitacyjne (ID)
      on update no action
      on delete no action,
  stanowisko   int      not null,
  constraint stanowiskoZ
    foreign key (stanowisko)
      references stanowiska (ID)
      on update no action
      on delete no action

);

create table stan_konta
(
  uzytkownik char(11) not null,
  constraint uzytkownikS
    foreign key (uzytkownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  saldo      int      not null
);

create table specjalizacje
(
  uzytkownik  char(11) not null,
  constraint uzytkownikSp
    foreign key (uzytkownik)
      references uzytkownicy (PESEL)
      on update no action
      on delete no action,
  uprawnienia varchar(45) not null,
  constraint uprawnieniaSp
    foreign key (uprawnienia)
      references uprawnienia (nazwa)
      on update no action
      on delete no action
);


create table dokumentacja
(
  data                      datetime     not null primary key,
  nazwa_obiektu_testowanego varchar(50)  not null,
  czas                      int          not null comment 'Czas jest podawany w sekundach.',
  ilosc_rekodrow            int          not null,
  comentarz                 varchar(100) not null
);

create table dostep_do_stanowiska
(
  stanowisko           varchar(45) not null,
  wymagane_uprawnienia varchar(45) not null,
  constraint wymagane_uprawnieniaD
    foreign key (wymagane_uprawnienia)
      references uprawnienia (nazwa)
      on update no action
      on delete no action
);

create table godziny_otwarcia
(
  ID int not null primary key,
  nazwa varchar(15) not null,
  godzina_rozpoczecia time not null,
  godzina_zaczonczenia time not null
);

insert into godziny_otwarcia (ID, nazwa, godzina_rozpoczecia, godzina_zaczonczenia)
VALUES (0, 'Niedziela', '08:00:00', '16:00:00'),
       (1, 'Poniedzialek', '08:00:00', '16:00:00'),
       (2, 'Wtorek', '08:00:00', '16:00:00'),
       (3, 'Sroda', '08:00:00', '16:00:00'),
       (4, 'Czwartek', '08:00:00', '16:00:00'),
       (5, 'Piatek', '08:00:00', '16:00:00'),
       (6, 'Sobota', '08:00:00', '16:00:00');

insert into uprawnienia(nazwa)
values ('Lasery A'),('Lasery B'),('Lasery C'),('Lasery D'),('Pole magnetyczne A'),('Pole magnetyczne B'),('Elektroterapia A'),('Elektroterapia C'),('Elektroterapia B'),('Ultradźwięki'),('Gimnastyka C'),('Gimnastyka B'),('Gimnastyka A'),('Gimnastyka D'),('Fizjoterapia A'),('Masaż mechaniczny'),('Krioterapia C'),('Krioterapia B'),('Krioterapia A'),('Fizjoterapia B'),('Gimnastyka dziecko'),('Gimnastyka dorośli'),('Gimnastyka grupy'),('Akupunktura A'),('Akupunktura C'),('Akupunktura B'),('Akupunktura D'),('Masaż relaksacyjny B'),('Masaż relaksacyjny C'),('Masaż relaksacyjny A'),('Kinesiotaping C'),('Kinesiotaping B'),('Kinesiotaping A'),('Masaż kobiet'),('Drenaż A'),('Drenaż B'),('Masaż klasyczny A'),('Masaż klasyczny C'),('Masaż klasyczny B');

insert into dostep_do_stanowiska (stanowisko, wymagane_uprawnienia)
values ('Lasery', 'Lasery A'),  ('Magnetokomora', 'Pole magnetyczne A'),  ('Elektrokomora', 'Elektroterapia A'),  ('Ultradźwięki komora', 'Ultradźwięki'),  ('Salka gimnastyczna', 'Gimnastyka A'),  ('Salka gimnastyczna', 'Gimnastyka dziecko'),  ('Salka gimnastyczna', 'Gimnastyka dorośli'),  ('Salka gimnastyczna', 'Gimnastyka grupy'),  ('Aquavibron', 'Fizjoterapia A'),  ('Wirówka', 'Masaż mechaniczny'),  ('Kriokomora', 'Krioterapia A'),  ('Lampy', 'Fizjoterapia B'),  ('Akupunktura', 'Akupunktura A'),  ('Salka spa', 'Masaż relaksacyjny A'),  ('Łóżko do masażu', 'Kinesiotaping A'),  ('Łóżko do masażu', 'Drenaż A'),  ('Łóżko do masażu', 'Masaż klasyczny A'),  ('Łóżko do masażu', 'Masaż kobiet'),  ('Łóżko do masażu', 'Akupunktura A');

DROP PROCEDURE IF EXISTS dodaj_stanowiska;
DELIMITER //
CREATE PROCEDURE dodaj_stanowiska()
BEGIN
  DECLARE i INT DEFAULT 0; #iterator po ilosci
  WHILE i <10 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery',2);
    SET i = i + 1;
  END WHILE;

  set i = 0;
    WHILE i <8 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery',4);
    SET i = i + 1;
  END WHILE;

  set i = 0;
    WHILE i <3 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Lasery',10);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <10 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora',2);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <8 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora',4);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <3 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Magnetokomora',10);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <10 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora',2);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <8 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora',4);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <3 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Elektrokomora',10);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <15 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Ultradźwięki komora',2);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <4 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna',15);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <7 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna',10);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <10 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna',6);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <16 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka gimnastyczna',2);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <20 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Aquavibron',1);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <25 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Wirówka',1);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <17 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Kriokomora',4);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <13 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Kriokomora',8);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <30 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Lampy',1);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <15 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Akupunktura',1);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <20 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Salka spa',1);
    SET i = i + 1;
  END WHILE;

  set i = 0;
  WHILE i <40 DO
    insert into stanowiska (nazwa, max_ilosc_osob) VALUES ('Łóżko do masażu',1);
    SET i = i + 1;
  END WHILE;

END//
DELIMITER ;


# ALTER TABLE uzytkownicy CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE uprawnienia CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE uslugi_rehabilitacyjne CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE transakcje CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE stanowiska CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE zabiegi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE stan_konta CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE specjalizacje CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE dokumentacja CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# ALTER TABLE dostep_do_stanowiska CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;



DROP PROCEDURE IF EXISTS dodaj_uzytkownika;
DELIMITER //
CREATE PROCEDURE dodaj_uzytkownika(IN ilosc INT, IN iloscklientow INT) #ilosc pracownikow = ilosc - iloscklientow - 1 (bo prezez)
BEGIN
  DECLARE i INT DEFAULT 0; #iterator po ilosci
  DECLARE j INT DEFAULT 0; #iterator po peselach w tym samym dniu
  DECLARE tesamedaty INT; #zmienna losowa odpowiasajaca za
  DECLARE rozmedaty INT DEFAULT 0; #diffeerent date
  DECLARE mindata DATE DEFAULT '2010-12-31'; #urodziny najmłodsej osoby
  DECLARE data DATE;
  DECLARE peselbezkontrolnej char(10);
  WHILE i < ilosc DO
  SET j = 0;
  SET data = DATE_SUB(mindata, INTERVAL rozmedaty DAY);
  SET tesamedaty = FLOOR(RAND() * 100 + 1);
  WHILE j < tesamedaty DO
  SET peselbezkontrolnej = CONCAT(
      SUBSTRING(YEAR(data), 3, 2),
      IF(YEAR(data) < 2000,
         LPAD(MONTH(data), 2, "0"),
         LPAD(MONTH(data) + 20, 2, "0")),
      LPAD(DAYOFMONTH(data), 2, "0"),
      cast((9999 - j) as char(4))
    );

  INSERT INTO uzytkownicy (PESEL, imie, nazwisko, data_dolaczenia, rola)
  VALUES (CONCAT(peselbezkontrolnej,
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
                     10)),
          ELT(FLOOR(RAND() * 624 + 1), 'Ada', 'Adalbert', 'Adam', 'Adela', 'Adelajda', 'Adrian', 'Aga', 'Agata', 'Agnieszka', 'Albert', 'Alberta', 'Aldona', 'Aleksander', 'Aleksandra', 'Alfred', 'Alicja', 'Alina', 'Amadeusz', 'Ambroży', 'Amelia', 'Anastazja', 'Anastazy', 'Anatol', 'Andrzej', 'Aneta', 'Angelika', 'Angelina', 'Aniela', 'Anita', 'Anna', 'Antoni', 'Antonina', 'Anzelm', 'Apolinary', 'Apollo', 'Apolonia', 'Apoloniusz', 'Ariadna', 'Arkadiusz', 'Arkady', 'Arlena', 'Arleta', 'Arletta', 'Arnold', 'Arnolf', 'August', 'Augustyna', 'Aurela', 'Aurelia', 'Aurelian', 'Aureliusz', 'Balbina', 'Baltazar', 'Barbara', 'Bartłomiej', 'Bartosz', 'Bazyli', 'Beata', 'Benedykt', 'Benedykta', 'Beniamin', 'Bernadeta', 'Bernard', 'Bernardeta', 'Bernardyn', 'Bernardyna', 'Błażej', 'Bogdan', 'Bogdana', 'Bogna', 'Bogumił', 'Bogumiła', 'Bogusław', 'Bogusława', 'Bohdan', 'Bolesław', 'Bonawentura', 'Bożena', 'Bronisław', 'Broniszław', 'Bronisława', 'Brunon', 'Brygida', 'Cecyl', 'Cecylia', 'Celestyn', 'Celestyna', 'Celina', 'Cezary', 'Cyprian', 'Cyryl', 'Dalia', 'Damian', 'Daniel', 'Daniela', 'Danuta', 'Daria', 'Dariusz', 'Dawid', 'Diana', 'Dianna', 'Dobrawa', 'Dominik', 'Dominika', 'Donata', 'Dorian', 'Dorota', 'Dymitr', 'Edmund', 'Edward', 'Edwin', 'Edyta', 'Egon', 'Eleonora', 'Eliasz', 'Eligiusz', 'Eliza', 'Elwira', 'Elżbieta', 'Emanuel', 'Emanuela', 'Emil', 'Emilia', 'Emilian', 'Emiliana', 'Ernest', 'Ernestyna', 'Erwin', 'Erwina', 'Eryk', 'Eryka', 'Eugenia', 'Eugeniusz', 'Eulalia', 'Eustachy', 'Ewelina', 'Fabian', 'Faustyn', 'Faustyna', 'Felicja', 'Felicjan', 'Felicyta', 'Feliks', 'Ferdynand', 'Filip', 'Franciszek', 'Salezy', 'Franciszka', 'Fryderyk', 'Fryderyka', 'Gabriel', 'Gabriela', 'Gaweł', 'Genowefa', 'Gerard', 'Gerarda', 'Gerhard', 'Gertruda', 'Gerwazy', 'Godfryd', 'Gracja', 'Gracjan', 'Grażyna', 'Greta', 'Grzegorz', 'Gustaw', 'Gustawa', 'Gwidon', 'Halina', 'Hanna', 'Helena', 'Henryk', 'Henryka', 'Herbert', 'Hieronim', 'Hilary', 'Hipolit', 'Honorata', 'Hubert', 'Ida', 'Idalia', 'Idzi', 'Iga', 'Ignacy', 'Igor', 'Ildefons', 'Ilona', 'Inga', 'Ingeborga', 'Irena', 'Ireneusz', 'Irma', 'Irmina', 'Irwin', 'Ismena', 'Iwo', 'Iwona', 'Izabela', 'Izolda', 'Izyda', 'Izydor', 'Jacek', 'Jadwiga', 'Jagoda', 'Jakub', 'Jan', 'Janina', 'January', 'Janusz', 'Jarema', 'Jarogniew', 'Jaromir', 'Jarosław', 'Jarosława', 'Jeremi', 'Jeremiasz', 'Jerzy', 'Jędrzej', 'Joachim', 'Joanna', 'Jolanta', 'Jonasz', 'Jonatan', 'Jowita', 'Józef', 'Józefa', 'Józefina', 'Judyta', 'Julia', 'Julian', 'Julianna', 'Julita', 'Juliusz', 'Justyn', 'Justyna', 'Kacper', 'Kaja', 'Kajetan', 'Kalina', 'Kamil', 'Kamila', 'Karina', 'Karol', 'Karolina', 'Kasper', 'Katarzyna', 'Kazimiera', 'Kazimierz', 'Kinga', 'Klara', 'Klarysa', 'Klaudia', 'Klaudiusz', 'Klaudyna', 'Klemens', 'Klementyn', 'Klementyna', 'Kleopatra', 'Klotylda', 'Konrad', 'Konrada', 'Konstancja', 'Konstanty', 'Konstantyn', 'Kordelia', 'Kordian', 'Kordula', 'Kornel', 'Kornelia', 'Kryspin', 'Krystian', 'Krystyn', 'Krystyna', 'Krzysztof', 'Ksenia', 'Kunegunda', 'Laura', 'Laurenty', 'Laurentyn', 'Laurentyna', 'Lech', 'Lechosław', 'Lechosława', 'Leokadia', 'Leon', 'Leonard', 'Leonarda', 'Leonia', 'Leopold', 'Leopoldyna', 'Lesław', 'Lesława', 'Leszek', 'Lidia', 'Ligia', 'Lilian', 'Liliana', 'Lilianna', 'Lilla', 'Liwia', 'Liwiusz', 'Liza', 'Lolita', 'Longin', 'Loretta', 'Luba', 'Lubomir', 'Lubomira', 'Lucja', 'Lucjan', 'Lucjusz', 'Lucyna', 'Ludmiła', 'Ludomił', 'Ludomir', 'Ludosław', 'Ludwik', 'Ludwika', 'Ludwina', 'Luiza', 'Lukrecja', 'Lutosław', 'Łucja', 'Łucjan', 'Łukasz', 'Maciej', 'Madlena', 'Magda', 'Magdalena', 'Makary', 'Maksym', 'Maksymilian', 'Malina', 'Malwin', 'Malwina', 'Małgorzata', 'Manfred', 'Manfreda', 'Manuela', 'Marcel', 'Marcela', 'Marceli', 'Marcelina', 'Marcin', 'Marcjan', 'Marcjanna', 'Marcjusz', 'Marek', 'Margareta', 'Maria', 'MariaMagdalena', 'Marian', 'Marianna', 'Marietta', 'Marina', 'Mariola', 'Mariusz', 'Marlena', 'Marta', 'Martyna', 'Maryla', 'Maryna', 'Marzanna', 'Marzena', 'Mateusz', 'Matylda', 'Maurycy', 'Melania', 'Melchior', 'Metody', 'Michalina', 'Michał', 'Mieczysław', 'Mieczysława', 'Mieszko', 'Mikołaj', 'Milena', 'Miła', 'Miłosz', 'Miłowan', 'Miłowit', 'Mira', 'Mirabella', 'Mirella', 'Miron', 'Mirosław', 'Mirosława', 'Modest', 'Monika', 'Nadia', 'Nadzieja', 'Napoleon', 'Narcyz', 'Narcyza', 'Nastazja', 'Natalia', 'Natasza', 'Nikita', 'Nikodem', 'Nina', 'Nora', 'Norbert', 'Norberta', 'Norma', 'Norman', 'Oda', 'Odila', 'Odon', 'Ofelia', 'Oksana', 'Oktawia', 'Oktawian', 'Olaf', 'Oleg', 'Olga', 'Olgierd', 'Olimpia', 'Oliwia', 'Oliwier', 'Onufry', 'Orfeusz', 'Oskar', 'Otto', 'Otylia', 'Pankracy', 'Parys', 'Patrycja', 'Patrycy', 'Patryk', 'Paula', 'Paulina', 'Paweł', 'Pelagia', 'Petronela', 'Petronia', 'Petroniusz', 'Piotr', 'Pola', 'Polikarp', 'Protazy', 'Przemysław', 'Radomił', 'Radomiła', 'Radomir', 'Radosław', 'Radosława', 'Radzimir', 'Rafael', 'Rafaela', 'Rafał', 'Rajmund', 'Rajmunda', 'Rajnold', 'Rebeka', 'Regina', 'Remigiusz', 'Rena', 'Renata', 'Robert', 'Roberta', 'Roch', 'Roderyk', 'Rodryg', 'Rodryk', 'Roger', 'Roksana', 'Roland', 'Roma', 'Roman', 'Romana', 'Romeo', 'Romuald', 'Rozalia', 'Rozanna', 'Róża', 'Rudolf', 'Rudolfa', 'Rudolfina', 'Rufin', 'Rupert', 'Ryszard', 'Ryszarda', 'Sabina', 'Salomea', 'Salomon', 'Samuel', 'Samuela', 'Sandra', 'Sara', 'Sawa', 'Sebastian', 'Serafin', 'Sergiusz', 'Sewer', 'Seweryn', 'Seweryna', 'Sędzisław', 'Sędziwoj', 'Siemowit', 'Sława', 'Sławomir', 'Sławomira', 'Sławosz', 'Sobiesław', 'Sobiesława', 'Sofia', 'Sonia', 'Stanisław', 'Stanisława', 'Stefan', 'Stefania', 'Sulimiera', 'Sulimierz', 'Sulimir', 'Sydonia', 'Sykstus', 'Sylwan', 'Sylwana', 'Sylwester', 'Sylwia', 'Sylwiusz', 'Symeon', 'Szczepan', 'Szczęsna', 'Szczęsny', 'Szymon', 'Ścibor', 'Świętopełk', 'Tadeusz', 'Tamara', 'Tatiana', 'Tekla', 'Telimena', 'Teodor', 'Teodora', 'Teodozja', 'Teodozjusz', 'Teofil', 'Teofila', 'Teresa', 'Tobiasz', 'Toma', 'Tomasz', 'Tristan', 'Trojan', 'Tycjan', 'Tymon', 'Tymoteusz', 'Tytus', 'Unisław', 'Ursyn', 'Urszula', 'Violetta', 'Wacław', 'Wacława', 'Waldemar', 'Walenty', 'Walentyna', 'Waleria', 'Walerian', 'Waleriana', 'Walery', 'Walter', 'Wanda', 'Wasyl', 'Wawrzyniec', 'Wera', 'Werner', 'Weronika', 'Wieńczysła', 'Wiesław', 'Wiesława', 'Wiktor', 'Wiktoria', 'Wilhelm', 'Wilhelmina', 'Wilma', 'Wincenta', 'Wincenty', 'Wińczysła', 'Wiola', 'Wioletta', 'Wirgiliusz', 'Wirginia', 'Wirginiusz', 'Wisław', 'Wisława', 'Wit', 'Witalis', 'Witold', 'Witolda', 'Witołd', 'Witomir', 'Wiwanna', 'Władysława', 'Władysław', 'Włodzimierz', 'Włodzimir', 'Wodzisław', 'Wojciech', 'Wojciecha', 'Zachariasz', 'Zbigniew', 'Zbysław', 'Zbyszko', 'Zdobysław', 'Zdzisław', 'Zdzisława', 'Zenobia', 'Zenobiusz', 'Zenon', 'Zenona', 'Ziemowit', 'Zofia', 'Zula', 'Zuzanna', 'Zygfryd', 'Zygmunt', 'Zyta', 'Żaklina', 'Żaneta', 'Żanna', 'Żelisław', 'Żytomir'),
          ELT(FLOOR(RAND() * 94 + 1), 'Nowak', 'Kowalski', 'Wiśniewski', 'Dąbrowski', 'Lewandowski', 'Wójcik', 'Kamiński', 'Kowalczyk', 'Zieliński', 'Szymański', 'Woźniak', 'Kozłowski', 'Jankowski', 'Wojciechowski', 'Kwiatkowski', 'Kaczmarek', 'Mazur', 'Krawczyk', 'Piotrowski', 'Grabowski', 'Nowakowski', 'Pawłowski', 'Michalski', 'Nowicki', 'Adamczyk', 'Dudek', 'Zając', 'Wieczorek', 'Jabłoński', 'Król', 'Majewski', 'Olszewski', 'Jaworski', 'Wróbel', 'Malinowski', 'Pawlak', 'Witkowski', 'Walczak', 'Stępień', 'Górski', 'Rutkowski', 'Michalak', 'Sikora', 'Ostrowski', 'Baran', 'Duda', 'Szewczyk', 'Tomaszewski', 'Pietrzak', 'Marciniak', 'Wróblewski', 'Zalewski', 'Jakubowski', 'Jasiński', 'Zawadzki', 'Sadowski', 'Bąk', 'Chmielewski', 'Włodarczyk', 'Borkowski', 'Czarnecki', 'Sawicki', 'Sokołowski', 'Urbański', 'Kubiak', 'Maciejewski', 'Szczepański', 'Kucharski', 'Wilk', 'Kalinowski', 'Lis', 'Mazurek', 'Wysocki', 'Adamski', 'Kaźmierczak', 'Wasilewski', 'Sobczak', 'Czerwiński', 'Andrzejewski', 'Cieślak', 'Głowacki', 'Zakrzewski', 'Kołodziej', 'Sikorski', 'Krajewski', 'Gajewski', 'Szymczak', 'Szulc', 'Baranowski', 'Laskowski', 'Brzeziński', 'Makowski', 'Ziółkowski', 'Przybylski'),
          DATE_SUB(CURRENT_DATE, INTERVAL FLOOR(RAND() * 4000 + 1) DAY),
          IF(i < iloscklientow, 'Pracownik', 'Klient '));
  SET i = i + 1;
  SET j = j + 1;
  END WHILE;
  SET rozmedaty = rozmedaty + FLOOR(RAND() * 200);
  END WHILE;
END//
DELIMITER ;

-- CALL dodajstanowiska();
-- CALL dodajuser(500,200);
