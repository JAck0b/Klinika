-- Tutaj są kody wszystkich procedur

delimiter //
create procedure czy_jest_gdzie_wolne_miejsce(in kiedy datetime, in id_pracownika char(11), in id_uslugi int,
                                              out czy_mozna boolean, out gdzie_wolne int)
begin
  declare obecna_ilosc_osob int default 0;
  declare maksymalna_liczba_osob int default 0;
  declare czas_zaplanowanych_zabiegow int default 0;
  declare uprawnienia_zaplanowanego_prowadzacego varchar(45);
  declare grupa_zaplanowanego_prowadzacego varchar(45);
  declare id_zaplanowanego_stanowiska int;

  declare czas_nowego_zabiegu int default 0;
  declare uprawnienia_nowego_zabiegu varchar(45);
  declare grupa_nowego_zabiegu varchar(45);

  set czy_mozna = false;
  set gdzie_wolne = -1;

  # wszystkie zabiegi w danym momencie wykonywane przez podanego pracownika
  create temporary table zabiegi_pomoc
  select *
  from zabiegi
  where pracownik like id_pracownika
    and data_zabiegu like kiedy;

  # znajdowanie uprawnień prowadzącego oraz jego grupy
  select uprawnienia.nazwa, uprawnienia.grupa
  from specjalizacje join uprawnienia on specjalizacje.uprawnienia = uprawnienia.nazwa
  where specjalizacje.uzytkownik like id_pracownika limit 1 into uprawnienia_zaplanowanego_prowadzacego, grupa_zaplanowanego_prowadzacego;

  # znajdowanie minimalnych uprawnień, grupy uprawnień oraz czasu nowego zebiegu
  select uprawnienia.nazwa, uprawnienia.grupa, uslugi_rehabilitacyjne.czas_trwania
  from uslugi_rehabilitacyjne join uprawnienia on uslugi_rehabilitacyjne.uprawnienia = uprawnienia.nazwa
  where uslugi_rehabilitacyjne.ID = id_uslugi limit 1 into uprawnienia_nowego_zabiegu, grupa_nowego_zabiegu, czas_nowego_zabiegu;

  # sprawdzenie, czy ten prowadzący w ogóle może prowadzić ten zabieg
  if grupa_nowego_zabiegu like grupa_zaplanowanego_prowadzacego and
     uprawnienia_nowego_zabiegu <= uprawnienia_zaplanowanego_prowadzacego then

    # znajdowanie ile osób jest teraz umówionych i jakie jest id stanowiska na którym będzie zabieg
    select count(ID), stanowisko
    from zabiegi_pomoc
    group by stanowisko into obecna_ilosc_osob, id_zaplanowanego_stanowiska;

    # znajdowanie czasu zaplanowanego zabiegu
    select distinct uslugi_rehabilitacyjne.czas_trwania
    from uslugi_rehabilitacyjne
           join zabiegi_pomoc on uslugi_rehabilitacyjne.ID = zabiegi_pomoc.usluga limit 1 into czas_zaplanowanych_zabiegow;

    # znajdowanie jaka jest maksymalna liczba osób na danym stanowisku
    select stanowiska.max_ilosc_osob
    from stanowiska
    where ID = id_zaplanowanego_stanowiska into maksymalna_liczba_osob;

    if obecna_ilosc_osob >= 1 and obecna_ilosc_osob + 1 < maksymalna_liczba_osob and
       czas_nowego_zabiegu = czas_zaplanowanych_zabiegow then
      # trzeba sprawdzic czy miejsce sie zgadza, czy czas jest ok oraz czy jest jeszcze miejsce

      set czy_mozna = true;
      set gdzie_wolne = id_zaplanowanego_stanowiska;

    else
      # trzeba znaleźć nowe puste stanowisko

#       select stanowiska.ID
#       from stanowiska
#              join zabiegi on stanowiska.ID = zabiegi.stanowisko
#              join dostep_do_stanowiska on stanowiska.nazwa = dostep_do_stanowiska.stanowisko
#              join uprawnienia on dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
#       where uprawnienia.nazwa like uprawnienia_nowego_zabiegu
#         and uprawnienia.grupa like grupa_nowego_zabiegu
#       having count(zabiegi.ID) = 0 limit 1 into gdzie_wolne;

      select stanowiska.ID
      from stanowiska
             left join zabiegi on stanowiska.ID = zabiegi.stanowisko
             join dostep_do_stanowiska on stanowiska.nazwa = dostep_do_stanowiska.stanowisko
             join uprawnienia on dostep_do_stanowiska.wymagane_uprawnienia = uprawnienia.nazwa
      where uprawnienia.grupa like grupa_nowego_zabiegu
        and zabiegi.data_zabiegu like kiedy
      group by stanowiska.ID
      having count(zabiegi.ID) = 0
      limit 1 into gdzie_wolne;

      if gdzie_wolne <> -1 then
        set czy_mozna = true;
      end if ;

    end if ;

  end if ;

end //
delimiter ;


# TODO można usunąć ilość i zostawić iterowanie po czasie
delimiter //
create procedure wolne_miejsca(in data date, in nazwa_uslugi varchar(100), in rodzaj_uslugi varchar(50))
begin
  declare iterator int default 0;
  declare warunek boolean default 0; # warunek czy jest dobra procedura
  declare rozpoczecie time; # godzina rozpoczęcia pracy w tym dniu
  declare zakonczenie time; # godzina zakończenia pracy w tym dniu
  declare ilosc int; # ilość przejść pętli
  declare czas_pomoc time; # iterator godzin
  declare koniec boolean default true;
  declare pracownik_pomoc char(11);
  declare id_uslugi int;
  declare id_stanowiska int;
  declare iterator cursor for (select uzytkownicy.PESEL # trzeba unikać selectowania zabiegów
                               from uzytkownicy
                                      join specjalizacje s on uzytkownicy.PESEL = s.uzytkownik
                                      join uprawnienia u on s.uprawnienia = u.nazwa
                                      join uslugi_rehabilitacyjne ur on u.nazwa = ur.uprawnienia
                               where ur.nazwa like nazwa_uslugi
                                 and ur.rodzaj like rodzaj_uslugi
                                 and uzytkownicy.rola like 'Pracownik');
  declare continue handler for not found set koniec = false;

  select godzina_zakonczenia
  from godziny_otwarcia
  where ID = dayofweek(data)
  limit 1 into zakonczenie;

  select godzina_rozpoczecia
  from godziny_otwarcia
  where ID = dayofweek(data)
  limit 1 into rozpoczecie;

  set ilosc = 4 * hour(timediff(zakonczenie, rozpoczecie));

  # ustalanie id danej usługi
  select ID
  from uslugi_rehabilitacyjne
  where nazwa like nazwa_uslugi
    and rodzaj like rodzaj_uslugi
  limit 1
    into id_uslugi;

  # można zmienić na wyszukiwanie dla każdego pracownika osobno, ale chyba lepiej tak
  create temporary table zabiegi_pomoc
  select *
  from zabiegi
  where usluga = id_uslugi
    and data_zabiegu like data;

  # tworzenie tablicy wyników
  drop table if exists wynik;
  create table wynik (pracownik char(11) not null, godzina time not null, stanowisko int not null);

  # chodzę po wszystkich pracownikach, którzy mogą prowadzić ten zabieg
  open iterator;
  fetch iterator into pracownik_pomoc;

  while koniec <> false do

    # chodzę po wszystkich
    set czas_pomoc = rozpoczecie;
    set iterator = 0;
    while iterator < ilosc do

    # procedura do której wrzucam pracownika, czas, usluge i zwraca mi czy moge gdzieś wrzucic osobe i gdzie
    call czy_jest_gdzie_wolne_miejsce(concat(data, ' ', czas_pomoc), pracownik_pomoc, id_uslugi, warunek, id_stanowiska);

      if (warunek = true) then
        insert into wynik (pracownik, godzina, stanowisko)
        VALUES (pracownik_pomoc, czas_pomoc, id_stanowiska);
      end if ;

      set czas_pomoc = addtime(czas_pomoc, '15:00');
      set iterator = iterator = 1;
    end while //


  fetch iterator into pracownik_pomoc;
  end while ;

  select * from wynik;

  drop temporary table if exists zabiegi_pomoc;
  drop table if exists wynik;

end //
delimiter ;

DROP PROCEDURE IF EXISTS doladowanie_konta;
DELIMITER //
CREATE PROCEDURE doladowanie_konta(IN PESEL char(11), IN kwota INT)
BEGIN
  UPDATE stan_konta SET saldo = saldo + kwota WHERE uzytkownik = PESEL;
END//
DELIMITER ;