#!/usr/bin/perl

use v5.16;              # использовать версию Perl не ниже указанной
use strict;             # включить дополнительные проверки
use warnings;           # и расширенную диагностику
use diagnostics;        # выводить подробную диагностику ошибок
use utf8;
use locale;
no warnings 'utf8';

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
my $VERBOSE = 0;

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



# данная функция производит обзвон абонентов по списку
sub expect_calls{
    # получаем имя файла с голосовым меню
    my $l_file = shift;

    # загружаем голосовое меню (файл menu.01.pl)
    my $menu = load_menu('menu.01.pl'); 

    # данная команда включает в модеме голосовой режим
    # один раз включив его можно удалить/заремарить
    # эту команду. Модем запомнит состояние.
    #at_send('AT^CVOICE=0'); 

    # данная команда включает в модеме отображение номера звонящего
    my $l_rec = at_send("AT+CLIP=1",qr/^(OK|ERROR)/);


    # цикл ожидания входящего звонка
    while ( ) {
        # при входящем звонке должно поступить сообщение RING
        $l_rec = at_rec(qr/^(RING)/);
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
    $call_info{phone} = at_rec(qr/^\+CLIP\: \"(\+\d+)/);
    $call_info{phone} =~s/^\+\d//;
    # генерим имя файла для записи
    $call_info{record_fname} = "phone_$call_info{phone}.time_$call_info{start_time}";

    # принимаем входящий вызов
    my $l_rec = at_send("ATA",qr/^(OK|ERROR)/);
    return 0 if $l_rec eq "ERROR";

    # ожидаем установления соединения
    $l_rec = at_rec(qr/^\^??(CONN\:1|CEND\:|ERROR)/);
    return 0 if $l_rec ne "CONN:1";

    # переключаем модем в режим приема/передачи голоса
    # OK - переключение прошло успешно
    # ERROR - переключение не произведено
    # CEND:.... - абонент недоступен, занят или сбросил вызов
    $l_rec = at_send('AT^DDSETEX=2',qr/(OK|ERROR|CEND\:)/);
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
    #play_voice($snd_out);

    # запоминаем время для отсчета 0.02 секунд
    my $before = gettimeofday;

    # основной цикл голосового меню
    while (){
        if ($snd_count == $snd_max) {
            if ($cmenu->{record} && $cmenu->{record}==1){
                    $snd_out = $menu->{standart_messages}{null}{title_voice};
                    $snd_max = scalar @{$snd_out};
                    $cmenu->{record}=2;
                    print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tПроизводится запись голосового сообщения в [./messages/$call_info{record_fname}.raw].\n";
            }

            $snd_count = 0;
        }

        syswrite  $SENDPORT_WAV, $snd_out->[$snd_count] , 320;

        sysread $SENDPORT_WAV, $snd_in, 320;
        
        if ($cmenu->{record} && $cmenu->{record} == 2) {
            syswrite  $l_fh, $snd_in, 320;
            $snd_savecount++;
        }

        $dtmf = dtmf_sample($snd_in);

        if ($dtmf) {
            #print "time: [$call_info{start_time}] \tphone: [$call_info{phoe}] \tНажата кнопка [$dtmf].\n";
            if ($dtmf eq '#') {
                print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tВыбран возврат в главное меню.\n";
                $cmenu->{record} = 1 if $cmenu->{record} && $cmenu->{record} == 2;
                $position = [$menu];
                $cmenu = $position->[0];
                $snd_out = $menu->{info_voice};
                $snd_count = 0;
                $snd_max = scalar @{$snd_out};
            } elsif ($dtmf eq '*') {
                if ((scalar @{$position}) > 1) {
                    print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tВыбран возврат в предыдущее меню.\n";
                    $cmenu->{record} = 1 if $cmenu->{record} && $cmenu->{record} == 2;
                    shift @{$position};
                    $cmenu = $position->[0];
                    $snd_out = $cmenu->{info_voice};
                    $snd_count = 0;
                    $snd_max = scalar @{$snd_out};
                }
            } elsif ($cmenu->{menu}) {
                if ($cmenu->{menu}{$dtmf}) {
                    $cmenu->{record} = 1 if $cmenu->{record} && $cmenu->{record} == 2;
                    $cmenu = $cmenu->{menu}{$dtmf};
                    print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tВыбран пункт меню [$cmenu->{title}].\n";
                    unshift @{$position}, $cmenu;
                    $snd_out = $cmenu->{info_voice};
                    $snd_count = 0;
                    $snd_max = scalar @{$snd_out};
                    if ($cmenu->{command}) {
                        print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tВыполнена команда [$cmenu->{command}].\n";
                        system "$cmenu->{command} &";
                    }
                } 
            }
        }

        # мониторим состояние звонка
        if ($checker==10) {
            $l_rec = at_send("AT+CLCC",qr/^\^??(OK|ERROR|CEND)/);
            # выходим если сброшен
            if ($l_rec eq "CEND") {
                $cmenu->{record} = 1 if $cmenu->{record} && $cmenu->{record} == 2;
                if ($snd_savecount){
                    $snd_savecount=0;
                    system 'sox -b 16 -r 8000 -e signed-integer ./messages/'.$call_info{record_fname}.'.raw ./messages/'.$call_info{record_fname}.'.flac gain -n -5 silence 1 5 2%';
                }
                system "rm ./messages/$call_info{record_fname}.raw" ;

                print "time: [$call_info{start_time}] \tphone: [$call_info{phone}] \tВызов завершен.\n";
                return 0
            }
            $checker=0;
        }

        # ряд управляющих циклом переменных
        $dtmf=0;
        $checker++;
        $snd_count++;

        # ожидаем остаток времени
        while( gettimeofday-$before < 0.02 ) { }
        $before = gettimeofday;
    }

    # Вешаем трубку.
    at_send('AT+CHUP');

    # закрываем файл с полученным сообщением
    close $l_fh;
}

sub play_voice{
    my $voice = shift;
    my $count = shift || 1;
    while ($count) {
        for my $sampe (@{$voice}){
            syswrite  $SENDPORT_WAV, $sampe, 320;
            #sleep(0.02);
            my $before = gettimeofday;
            while( gettimeofday-$before < 0.02 ) { }
        }
        $count--;
    }
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
    my $l_rx = shift || qr/(OK)/;
    print $SENDPORT "$l_cmd\r";
    print "SEND: [$l_cmd]\n" if $VERBOSE;
    return at_rec($l_rx);
}


# данная функция ждет от модема ответа указанного в регулярном выражении 
# принимает 1 параметра - регулярное выражение описывающее варианты ожидаемых ответов (по умолчанию OK)
sub at_rec{
    my $l_rx = shift || qr/OK/;
    my $recive='';
    #print "white: [$l_rx]\n";
    until ( $recive=~$l_rx ) {
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

