#!/usr/bin/perl

my $pin='xxxx';

my %at=(
    mode_switch=>{
	modem_only=>{
	    command=>'AT^U2DIAG=0',
	    info=>'режим [только модем]',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'модем переключен в режим [только модем].'},
		"ERROR"=>{execute=>sub{},info=>'не удалось переключить модем в режим [только модем].'},
	    }
	},
	modem_cdrom=>{
	    command=>'AT^U2DIAG=1',
	    info=>'режим [модем и cdrom]',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'модем переключен в режим [модем и cdrom].'},
		"ERROR"=>{execute=>sub{},info=>'не удалось переключить модем в режим [модем и cdrom].'},
	    }
	},
	modem_only=>{
	    command=>'AT^U2DIAG=255',
	    info=>'режим [модем, cdrom и кардридер]',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'модем переключен в режим [модем, cdrom и кардридер].'},
		"ERROR"=>{execute=>sub{},info=>'не удалось переключить модем в режим [модем, cdrom и кардридер].'},
	    }
	},
	modem_only=>{
	    command=>'AT^U2DIAG=256',
	    info=>'режим [модем и кардридер]',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'модем переключен в режим [модем и кардридер].'},
		"ERROR"=>{execute=>sub{},info=>'не удалось переключить модем в режим [модем и кардридер].'},
	    }
	}
    },
    pin_switch=>{
	enter_pin=>{
	    command=>'at+cpin="$pin"',
	    info=>'ввести PIN код',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'PIN код принят. проверте.'},
		"ERROR"=>{execute=>sub{},info=>'PIN код не принят. введите повторно.'},
	    }
	},
	test_pin=>{
	    command=>'AT+CLCK="SC",2',
	    info=>'проверяет корректно ли введен PIN код. возвращает 1 если корректно. возвращает 0 если не корректно'б
	    returns=>{
		"1"=>{execute=>sub{},info=>'PIN код введен корректно'},
		"0"=>{execute=>sub{},info=>'PIN код введен некорректно'},
	    }
	},
	disable_pin=>{
	    command=>'AT+CLCK="SC",0,"$pin"',
	    info=>'отключить проверку PIN кода',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'PIN код отключен.'},
		"ERROR"=>{execute=>sub{},info=>'не удалось отключить PIN код.'},
	    }
	},
	enable_pin=>{
	    command=>'AT+CLCK="SC",1,"$pin"',
	    info=>'включить проверку PIN кода',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'PIN код включен.'},
		"ERROR"=>{execute=>sub{},info=>'не удалось включить PIN код.'},
	    }
	},
    },
    get_info=>{
	other_info=>{
	    command=>'ATI',
	    info=>'разная информация'
	},
	firmware_version=>{
	    command=>'AT+CGMR',
	    info=>'версия прошивки'
	},
	imei=>{
	    command=>'AT+CGSN',
	    info=>'IMEI модема'
	},
    },
    voice_switch=>{
	test_voice=>{
	    command=>'AT^CVOICE=?',
	    info=>'проверка состояния',
	    returns=>{
		"1"=>{execute=>sub{},info=>'voice выключен.'},
		"0"=>{execute=>sub{},info=>'voice включен.'},
	    }
	},
	enable_voice=>{
	    command=>'AT^CVOICE=0',
	    info=>'включить voice',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'voice включен.'},
		"ERROR"=>{execute=>sub{},info=>'не удалось включить voice.'},
	    }
	},
	disable_voice=>{
	    command=>'AT^CVOICE=1',
	    info=>'выключить voice',
	    returns=>{
		"OK"=>{execute=>sub{},info=>'voice выключен.'},
		"ERROR"=>{execute=>sub{},info=>'не удалось выключить voice.'},
	    }
	},
    }

);