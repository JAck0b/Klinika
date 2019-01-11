-- Tutaj są kody wszystkich procedur
# To nie jest jeszcze gotowa funkcja. Musi poczekać na swoją kolej.
delimiter //
create procedure wolne_terminy_zabiegu(in data date, in naz varchar(100), in rodz varchar(50))
begin
  declare iterator1 int default 0;
  declare warunek boolean default 0;
  declare ilosc int default 4 * timediff(select
                                         godziny_otwarcia.godzina_rozpoczecia # obliczanie ile jest kwadransów w godzinach pracy
                                         from godziny_otwarcia
                                         where godzina_rozpoczecia.ID = dayofweek(data) limit 1, select
                                         godziny_otwarcia.godzina_zakonczenia
                                         from godziny_otwarcia
                                         where godzina_rozpoczecia.ID = dayofweek(data) limit 1);
  declare czas time;
  declare czas_pomoc time;
  declare koniec int default true;
  declare pracownik_pomoc char(11);
  declare id_uslugi int;
  declare iterator cursor for select uzytkownicy.PESEL
                              from uzytkownicy
                                     join specjalizacje s on uzytkownicy.PESEL = s.uzytkownik
                                     join uprawnienia u on s.uprawnienia = u.nazwa
                                     join uslugi_rehabilitacyjne ur on u.nazwa = ur.uprawnienia
                              where ur.nazwa like naz
                                and ur.rodzaj like rodz;
  declare continue handler for not found set koniec = false;

  # ustalanie id danej usługi
  select ID
  from uslugi_rehabilitacyjne
  where nazwa like naz
    and rodzaj like rodz
  limit 1
    into id_uslugi;

  # można zmienić na wyszukiwanie dla każdego pracownika osobno
  create temporary table zabiegi_pomoc
  select *
  from zabiegi
  where usluga = id_uslugi
    and data_zabiegu like data;

  # ustalanie godziny rozpoczecia pracy kliniki w danym dniu
  select godziny_otwarcia.godzina_rozpoczecia
  from godziny_otwarcia
  where godzina_rozpoczecia.ID = dayofweek(data) # dobra godzina
        into czas;


  open iterator;
  fetch iterator into pracownik_pomoc;
  while koniec <> true do # przejście po wszystkich pracownikach, którzy spełniają warunki

  set czas_pomoc = czas;
    set iterator1 = 0;
    while iterator1 < ilosc do # przejście po wszystkich godzinach

      set warunek = if ();


      set iterator1 = iterator1 + 1;
      set czas_pomoc = addtime(czas_pomoc, '15:00');
    end while ;

    fetch iterator into pracownik_pomoc;
  end while;
  close iterator;
end //
delimiter ;

#############################################################################################################
# ta procedura liczy czy są wolne miejsca i czy nie będzie ten nowy zabieg przeszkadzać w przyszłości
delimiter //
create procedure czy_sa_wolne_miejsca_na_stanowisku_ciagle(in data date, in godzina time, in id_uslugi int,
                                                           in id_stanowiska int, out wynik boolean)
begin
  declare dlugosc_trwania int;
  declare iterator int default 0;
  declare ilosc_powtorzen int default 0;
  declare ilosc_w_jednym_czasie int default 0;
  declare max_ilosc_w_danym_momencie int default 0;

  set wynik = true;

  select uslugi_rehabilitacyjne.czas_trwania
  from uslugi_rehabilitacyjne
  where uslugi_rehabilitacyjne.ID = id_uslugi into dlugosc_trwania;

  select uslugi_rehabilitacyjne.max_ilosc_osob
  from uslugi_rehabilitacyjne
  where uslugi_rehabilitacyjne.ID = id_uslugi into max_ilosc_w_danym_momencie;

  set ilosc_powtorzen = dlugosc_trwania / 15;

  create temporary table zabiegi_pomoc
  select *
  from zabiegi
  where zabiegi.stanowisko = id_stanowiska
    and date(zabiegi.data_zabiegu) like data;

  myloop: while iterator < ilosc_powtorzen do
  select count(zabiegi_pomoc.ID)
  from zabiegi_pomoc
  where time(zabiegi_pomoc.data_zabiegu) like godzina into ilosc_w_jednym_czasie;
  if (ilosc_w_jednym_czasie >= max_ilosc_w_danym_momencie) then # jeżeli jest równe to nie ma miejsca dla następnego
    set wynik = false;
    #     leave myloop;
  end if ;
  set iterator = iterator + 1;
  set godzina = addtime(godzina, '15:00');
  end while;
end //
delimiter ;
