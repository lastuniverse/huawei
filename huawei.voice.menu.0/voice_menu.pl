#!/usr/bin/perl

use v5.16;              # использовать версию Perl не ниже указанной
use strict;             # включить дополнительные проверки
use warnings;           # и расширенную диагностику
use diagnostics;        # выводить подробную диагностику ошибок
#use utf8;
#use locale;
#no warnings 'utf8';

# подключаем модуль Time::HiRes и импортируем
# в текущее пространство имен функцию sleep
# особенность данной функции - возможность указывать
# задержку меньше секунды
use Time::HiRes qw(sleep usleep gettimeofday);

# подключаем модуль dtmf_decoder
use dtmf_decoder;


# Для информации:
# Сообщения типа CEND выдаются модемом при завершении вызова
# и содержат в себе информацию о вызове, о причине завершения вызова
# и о состоянии устройства.
# формат вывода ^CEND:call_index, duration, end_status, cc_cause
# где:
# call_index - уникальный идентификатор вызова
# duration - длительность вызова в секундах
# end_status - код статуса устройства после завершения вызова
# cc_cause - код причины завершения вызова

# при подключении модема к компьютеру с OS Linux
# создаются 3 usb интерфейса для обмена данными с модемом
# обычно это:
# /dev/ttyUSB0 - командный интерфейс модема
# /dev/ttyUSB1 - голосовой(при включенном голосовом режиме) интерфейс модема
# /dev/ttyUSB2 - командный интерфейс модема. Отличается от /dev/ttyUSB0 тем
# что с него можно читать не только ответы модема на команды, а также служебные
# сообщения. Такие как данные о качестве сигнала, вывод ^CEND и прочее

# указываем порт для отсылки модему звука
my $VOICE_PORT = "/dev/ttyUSB1";

# указываем порт для подачи модему команд
my $COMMAND_PORT = "/dev/ttyUSB2";

# устанавливаем в:
# 0 - чтобы отключить вывод отладочной информации
# 1 - чтобы включить вывод отладочной информации
my $VERBOSE = 1;

# Открываем командный порт модема на чтение и запись
open my $SENDPORT, '+<', $COMMAND_PORT or die "Can't open '$COMMAND_PORT': $!\n";

# Открываем голосовой  порт модема на чтение и запись
# чтение аудио потока из порта в данной программе не используется
# но вам ничто не мешает превратить данный скрипт в автоответчик например
open my $SENDPORT_WAV, '+<', $VOICE_PORT or die "Can't open '$VOICE_PORT': $!\n";


# вызываем функцию ожидания вызовов, которой передаются 1 параметр:
#  - имя файла с голосовым меню
expect_calls('menu.01.pl');

# по окончании обзвона закрываем все открытые файлы/порты
exit_call();


# AT&V # посмотреть текущие настройки модема
# &C: 2; &D: 2; &E: 0; &F: 0; &S: 0; &W: 0; E: 1; L: 0; M: 0; Q: 0; V: 1;
# X: 0; Z: 0; \Q: 3; \S: 0; \V: 0; S0: 0; S2: 43; S3: 13; S4: 10; S5: 8;
# S6: 2; S7: 50; S8: 2; S9: 6; S10: 14; S11: 95; S30: 0; S103: 1; S104: 1;
# +FCLASS: 0; +ICF: 3,3; +IFC: 2,2; +IPR: 115200; +DR: 0; +DS: 0,0,2048,6;
# +WS46: 12; +CBST: 0,0,1;
# +CRLP: (61,61,48,6,0),(61,61,48,6,1),(240,240,52,6,2);
# +CV120: 1,1,1,0,0,0; +CHSN: 0,0,0,0; +CSSN: 0,0; +CREG: 0; +CGREG: 0;
# +CFUN:; +CSCS: "IRA"; +CSTA: 129; +CR: 0; +CRC: 0; +CMEE: 0; +CGDCONT: (1,"IP","internet.mts.ru","0.0.0.0",0,0),(2,"IP","internet","0.0.0.0",0,0),(3,"IP","internet.mts.ru","0.0.0.0",0,0)
# ; +CGDSCONT: ; +CGTFT: ; +CGEQREQ: (1,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(2,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(3,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(4,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(5,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(6,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(7,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(8,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(9,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(10,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(11,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(12,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(13,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(14,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(15,4,0,0,0,0,2,0,"0E0","0E0",3,0,0),(16,4,0,0,0,0,2,0,"0E0","0E0",3,0,0)
# ; +CGEQMIN: ; +CGQREQ: ; +CGQMIN: ; ; +CGEREP: 0,0; +CGCLASS: "B";
# +CGSMS: 1; +CSMS: 0; +CMGF: 0; +CSAS: 0; +CRES: 0;
# +CSCA: "+79114599913",145; +CSMP: ,,0,0; +CSDH: 0; +CSCB: 0,"","";
# +FDD: 0; +FAR: 0; +FCL: 0; +FIT: 0,0; +ES: ,,; +ESA: 0,,,,0,0,255,;
# +CMOD: 0; +CVHU: 1; ; +CPIN: ,; +CMEC: 0,0,0;  +CKPD: 1,1; +CGATT: 1;
# +CGACT: 0; +CPBS: "SM"; +CPMS: "SM","SM","SM"; +CNMI: 0,0,0,0,0;
# +CMMS: 2; +FTS: 0; +FRS: 0; +FTH: 3; +FRH: 3; +FTM: 96; +FRM: 96;
# +CCUG: 0,0,0; +COPS: 0,2,""; +CUSD: 0; +CAOC: 1; +CCWA: 0; +CCLK: "";
# +CLVL: 2; +CMUT: 1; +CPOL: 0,2,"",0,0,0; +CPLS: 0; +CTZR: 0; +CTZU: 0;
# +CLIP: 0; +COLP: 0; +CDIP: 0; +CLIR: 0; ^PORTSEL: 0; ^CPIN: ,;
# ^ATRECORD: 0; ^FREQLOCK: 8859956,0; ^CVOICE: 0; ^DDSETEX: 0; ^CMSR: 0; ;
# ^AUTHDATA: 1,0,"",""; ^CRPN: 0,"" 

# AT^CURC=?  # Узнать возможные варианты (0,1)
# AT^CURC?   # Узнать выбранный вариант (1)
# AT^CURC=0  # Отключить вывод сообщений о уровне сигнала

# данная функция производит обзвон абонентов по списку
sub expect_calls{
    # получаем имя файла с голосовым меню
    my $l_file = shift;

    my $l_rec;

    # загружаем голосовое меню (файл menu.01.pl)
    my $menu = load_menu('menu.01.pl'); 


    $l_rec = at_send('ATQ0'); sleep(0.2);

    $l_rec = at_send('AT^CURC=0'); sleep(0.2);

    # данная команда включает в модеме голосовой режим
    # один раз включив его можно удалить/заремарить
    # эту команду. Модем запомнит состояние.
    $l_rec = at_send('AT^CVOICE=0'); sleep(0.2);

    # данная команда включает в модеме отображение номера звонящего
    $l_rec = at_send("AT+CLIP=1",qr/^(OK|ERROR)/); sleep(0.2);


    # цикл ожидания входящего звонка
    while ( ) {
        # при входящем звонке должно поступить сообщение RING
        $l_rec = at_rec(qr/^(RING)/); sleep(0.2);
        accept_call($menu);
    }
}


# данная функция производит попытку вызова указного номера
# и в случае успеха - транслирует голосовое сообщение
sub accept_call{
    my $menu = shift;

    # в этом массиве хранится стtк перемещений по меню
    my $position = [$menu];

    # текущее меню
    my $cmenu = $position->[0];

    my %call_info = ();
    # запоминаем время начала
    $call_info{start_time} = time;
    # ждем сообщения с номером телефона звонящего абонента #+CLIP: "+79117654321",145,,,,0
    $call_info{phone} = at_rec(qr/^\+CLIP\: \"(\+\d+)/); sleep(0.2);
    $call_info{phone} =~s/^\+\d//;
    # генерим имя файла для записи
    $call_info{record_fname} = "phone_$call_info{phone}.time_$call_info{start_time}";

    # принимаем входящий вызов
    my $l_rec = at_send("ATA",qr/^\^??(CONN\:1|CE ND\:|OK|ERROR)/); sleep(0.2);
    return 0 if $l_rec eq "ERROR";

    if ($l_rec eq "OK") {
        # ожидаем установления соединения
        $l_rec = at_rec(qr/^\^??(CONN\:1|CEND\:|ERROR)/); sleep(0.2);
    }
    return 0 if $l_rec ne "CONN:1";

    # переключаем модем в режим приема/передачи голоса
    # OK - переключение прошло успешно
    # ERROR - переключение не произведено
    # CEND:.... - абонент недоступен, занят или сбросил вызов
    $l_rec = at_send('AT^DDSETEX=2',qr/(OK|ERROR|CEND\:)/); sleep(0.2);
    return 0 if $l_rec ne "OK";

    # Если дошли до сюда - значит вызов установлен
    # Звук модему и от него передается порциями по 320 байт каждые 0.02 секунды
    print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \t"."Вызов принят.\n";

    my $checker = 0;

    my $dtmf = 0;

    # буфер для входящих аудиоданных данных
    my $snd_in;
    
    # буфер для исходящих аудиоданных данных
    my $snd_out = $cmenu->{info_voice};
    my $snd_count = 0;
    my $snd_savecount = 0;
    my $snd_max = scalar @{$snd_out};


    # открываем файл для записи входящего аудиопотока
    my $l_fh = new IO::File "> ./messages/$call_info{record_fname}.raw" or die "Cannot open $call_info{record_fname}.raw : $!";
    binmode($l_fh);

    # Устанавливаем служебную переменную $| в единицу это отключает буферизацию.
    # Таким образом данные в звуковой порт будут отправляться незамедлительно.
    $|=1;

    # проигрываем приветстви
    play_voice($snd_out);

    # запоминаем время для отсчета 0.02 секунд
    my $before = gettimeofday;

    # основной цикл голосового меню
    # while (){
    #     if ($snd_count == $snd_max) {
    #         $snd_count = 0;
    #     }

    #     syswrite  $SENDPORT_WAV, $snd_out->[$snd_count] , 320;

    #     # ряд управляющих циклом переменных
    #     $snd_count++;

    #     # ожидаем остаток времени
    #     while( gettimeofday-$before < 0.02 ) { }
    #     $before = gettimeofday;
    # }

    # Вешаем трубку.
    at_send('AT+CHUP'); sleep(0.2);

    # закрываем файл с полученным сообщением
    close $l_fh;
}

sub play_voice{
    my $voice = shift;
    my $count = shift || 1;
    my $before = gettimeofday;
    my $current = $before;

    # открываем файл для записи исходящего аудиопотока
    #my $l_fh = new IO::File "> ./test.raw" or die "test.raw : $!";
    #binmode($l_fh);

    while ($count) {
        for my $sampe (@{$voice}){
            # Устанавливаем служебную переменную $| в единицу это отключает буферизацию.
            # Таким образом данные в звуковой порт будут отправляться незамедлительно.
            $|=1;
            #syswrite  $l_fh, $sampe, 320;
            syswrite  $SENDPORT_WAV, $sampe, 320;

            $current=gettimeofday;
            print "TIMEOUT: [".($current-$before)."]\n" if $current-$before >= 0.02;
            while( $current-$before < 0.02 ) { $current=gettimeofday; }
            $before = $current;
        }
        $count--;
    }

    #close($l_fh);
}

# данная функция загружает голосовое меню
sub load_menu{
    my $l_file_name = shift;
    my %voice_menu = do $l_file_name;
    $voice_menu{standart_messages}{null}{title_voice} = load_voice($voice_menu{standart_messages}{null}{title_voice_fname});
    $voice_menu{standart_messages}{back}{title_voice} = load_voice($voice_menu{standart_messages}{back}{title_voice_fname});
    $voice_menu{standart_messages}{back_to_main}{title_voice} = load_voice($voice_menu{title_voice_fname});
    load_menu_voices(\%voice_menu,$voice_menu{standart_messages});
    return \%voice_menu;
}

# данная функция загружает аудиофайлы голосового меню
sub load_menu_voices{
    my $menu = shift;
    my $standart_messages = shift;
    $menu->{info_voice} = load_voice($menu->{info_voice_fname});
    for my $key (sort {$a <=> $b} keys %{$menu->{menu}}){
        my $cur = $menu->{menu}{$key};
        my $sub_voice = load_menu_voices($cur,$standart_messages);
        $menu->{info_voice} = [@{$menu->{info_voice}},@{$sub_voice}];
    }
    $menu->{info_voice} = [ @{$menu->{info_voice}},
                            @{$standart_messages->{back}{title_voice}},
                            @{$standart_messages->{back_to_main}{title_voice}},
                            @{$standart_messages->{null}{title_voice}},
                            @{$standart_messages->{null}{title_voice}}
                          ];
    return load_voice($menu->{title_voice_fname});
}

# данная функция загружает голосовое сообщение в массив кусками по 320 байт
# принимает 1 параметр - имя файла
# формат звуковых данных - pcm, моно, 8000 кГц, 16 бит, signed
sub load_voice{
    my $l_file_name = shift;
    print "FILENAME: [$l_file_name]\n";
    my $l_fh = new IO::File "< $l_file_name" or die "Cannot open $l_file_name : $!";
    binmode($l_fh);
    my @l_bufer = ();
    my $i=0;
    while (read($l_fh,$l_bufer[$i],320)) { $i++; }
    close $l_fh;
    return \@l_bufer;
}


# данная функция отправляет команду в командный порт модема
# и ждет ответа указанного в регулярном выражении
# принимает 2 параметра:
# 1-й - команда
# 2-й - регулярное выражение описывающее варианты ожидаемых ответов (по умолчанию OK)
sub at_send{
    my $l_cmd = shift;
    my $l_rx = shift || qr/(OK|ERROR)/;
    print $SENDPORT "$l_cmd\r";
    print "SEND: [$l_cmd]\n" if $VERBOSE;
    return at_rec($l_rx);
}


# данная функция ждет от модема ответа указанного в регулярном выражении 
# принимает 1 параметра - регулярное выражение описывающее варианты ожидаемых ответов (по умолчанию OK)
sub at_rec{
    my $l_rx = shift || qr/(OK|ERROR)/;
    my $recive='';
    print "white: [$l_rx]\n";
    until ( $recive=~$l_rx ) {
        sleep(0.02);
        $recive=<$SENDPORT>;
        $recive=~s/[\n\r]+//msg;
        print "RECIVE: [$recive]\n" if $VERBOSE && $recive;
    }
    $recive=~$l_rx;
    print "END RECIVE: [$recive] [$1] [$l_rx]\n" if $VERBOSE;
    return $1;
}


# данная функция закрывает ранее открытые порты модема
sub exit_call{
    print "ОПОВЕЩЕНИЕ ОКОНЧЕНО\n";
    close $SENDPORT_WAV;
    at_send('AT+CHUP');
    close $SENDPORT;
}

