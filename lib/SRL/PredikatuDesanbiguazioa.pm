##
#
#  Copyright (C) 2017 IXA Taldea, University of the Basque Country UPV/EHU
#
#  This file is part of ixa-pipe-srl-eu.
#
#  ixa-pipe-srl-eu is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  ixa-pipe-srl-eu is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with ixa-pipe-srl-eu.  If not, see <http://www.gnu.org/licenses/>.
#
##

package SRL::PredikatuDesanbiguazioa;
use strict;
use warnings;
use File::Copy qw(copy);
use LWP::UserAgent;
use HTTP::Request;
use XML::LibXML;

use Exporter qw(import);
our @EXPORT_OK = qw(erauzi_PD aurreprozesatu adierak_lortu_zero adierak_lortu_bat adierak_lortu_bi esaldia_adiera_anitz esaldia_adiera_bakar esaldia_adiera_itzulp sortu_test_PD iragarri_PD anitz_sortu bateratu_iragarpenak sortu_identifikaziorakoa);


my $logger = Log::Log4perl->get_logger();


sub irakurri_dir($) {
    my($dir) = @_;
    my(@files);
    local(*DIR);
    if (!opendir(DIR, $dir)) { return () }
    @files = sort(grep(!/^(\.|\.\.)$/, readdir(DIR)));
    closedir(DIR);
    return @files
}


sub erauzi_PD {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/Esaldi_Berriak_PI_$pId";
    my $dir_ezaug = "$dir/tmp/$pId/Ezaugarriak_Desanb_$pId";
    if (-d $dir_ezaug) {
	system("rm -rf $dir_ezaug");
    }
    system("mkdir $dir_ezaug");

    my $dir_kasufitx = "$dir/tmp/$pId/KASUA_Conll_$pId";
    foreach my $fp (irakurri_dir($dir_test)) {
	my $helb = "$dir_test/$fp";
	open my $ftrain, "<:encoding(UTF-8)", $helb or die "Ezin da $helb fitxategia ireki-0: $!\n";
	my %hash = ();
	open my $ftrain_hash, "<:encoding(UTF-8)", $helb or die "Ezin da $helb fitxategia ireki-1: $!\n";
	my $aurreko2_train = "";
	my $aurreko_train = "";
	my $uneko_train = "";
	while (my $lerroa_train_hash = <$ftrain_hash>) {
	    chomp($lerroa_train_hash);
	    $aurreko2_train = $aurreko_train;
	    $aurreko_train = $uneko_train;
	    $uneko_train = $lerroa_train_hash;
	    $uneko_train =~ s/^\s*//;
	    $uneko_train =~ s/\s*$//;
	    my @zati_hash = split(/\t/, $uneko_train);
	    my $gakoa = scalar($zati_hash[0]);
	    $hash{$gakoa} = $uneko_train;
	}
	close $ftrain_hash or die "Ezin da $ftrain_hash fitxategia itxi: $!\n";
	my @zatiak_bidea = split(/\//, $helb);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_izena = $zatiak_bidea[$KOKZ];
	my @zatizen = split(/\.conll09/, $fitx_izena);
	my $izs = "";
	if ($zatizen[0] =~ m/izas\_/) {
	    my @zat = split(/izas\_/, $zatizen[0]);
	    $izs = $zat[1];
	}
	elsif ($zatizen[0] =~ m/maxux\_/) {
	    my @zat = split(/maxux\_/, $zatizen[0]);
	    $izs = $zat[1];
	}
	elsif ($zatizen[0] =~ m/ainara\_/) {
	    my @zat = split(/ainara\_/, $zatizen[0]);
	    $izs = $zat[1];
	}

	my $fitx_izena1 = "$izs.conll08";
	my $aurreko2_lerroa_train = "";
	my $aurreko_lerroa_train = "";
	my $uneko_lerroa_train = "";
	while (my $lerroa_train = <$ftrain>) {
	    chomp($lerroa_train);
	    $aurreko2_lerroa_train = $aurreko_lerroa_train;
	    $aurreko_lerroa_train = $uneko_lerroa_train;
	    $uneko_lerroa_train = $lerroa_train;
	    $uneko_lerroa_train =~ s/^\s*//;
	    $uneko_lerroa_train =~ s/\s*$//;
	    my @ler_zat = split(/\t/, $uneko_lerroa_train);
	    if ($uneko_lerroa_train =~ m/\#1/) {
		my $hitz_zenb = $ler_zat[0];
		my $fitx_ez = "$dir_ezaug/$fitx_izena.$hitz_zenb.Ezaugarriak";
		open my $fezaug, ">:encoding(UTF-8)", $fitx_ez or die "Ezin da $fitx_ez ireki-2: $!\n";
		print $fezaug "0.ID#$fitx_izena.$hitz_zenb.Ezaugarriak\n";
		my $hitza = $ler_zat[1];
		$hitza =~ s/\%//g;
		print $fezaug "1.hitza#$hitza\n";
		my $hlema = $ler_zat[2];
		if ($hlema eq "") {
		    $hlema = "-";
		}
		$hlema =~ s/\%//g;
		print $fezaug "2.lema#$hlema\n";
		my $pos = $ler_zat[3];
		print $fezaug "3.PoS#$pos\n";
		my $apos = $ler_zat[4];
		print $fezaug "4.azpiPoS#$apos\n";
		my $depetik = $ler_zat[6];
		print $fezaug "5.Depend#$depetik\n";
		my $buruhitz = "-";
		my @parent;
		if (exists $hash{$ler_zat[5]}) {
		    @parent = split(/\t/, $hash{$ler_zat[5]});
		}
		if (defined($parent[1])) {
		    $buruhitz = $parent[1];
		}
		$buruhitz =~ s/\%//g;
		print $fezaug "6.BuruHitz#$buruhitz\n";
		my $burulema = "-";
		if (defined($parent[2])) {
		    $burulema = $parent[2];
		}
		if ($burulema eq "") {
		    $burulema = "-";
		}
		$burulema =~ s/\%//g;
		print $fezaug "7.BuruLema#$burulema\n";
		my $burupos = "-";
		if (defined($parent[3])) {
		    $burupos = $parent[3];
		}
		print $fezaug "8.BuruPoS#$burupos\n";
		my $buruapos = "-";
		if (defined($parent[4])) {
		    $buruapos = $parent[4];
		}
		print $fezaug "9.BuruazpiPoS#$buruapos\n";
		my $klasea = "BAL";
		my $semedepset = "-";
		my $semehitzset = "-";
		my $semelemaset = "-";
		foreach my $keyg (sort {$a<=>$b} keys %hash) {
		    my @seme_lerro = split(/\t/, $hash{$keyg});
		    if (defined $seme_lerro[5]) {
			if ($seme_lerro[5] eq $hitz_zenb) {
			    $semedepset .= "$seme_lerro[6]|";
			    $semehitzset .= "$seme_lerro[1]|";
			    $semelemaset .= "$seme_lerro[2]|";
			}
		    }
		}
		if ($semedepset ne "-") {
		    chop($semedepset);
		    $semedepset = reverse($semedepset);
		    chop($semedepset);
		    $semedepset = reverse($semedepset);
		    chop($semehitzset);
		    $semehitzset = reverse($semehitzset);
		    chop($semehitzset);
		    $semehitzset = reverse($semehitzset);
		    chop($semelemaset);
		    $semelemaset = reverse($semelemaset);
		    chop($semelemaset);
		    $semelemaset = reverse($semelemaset);
		}
		print $fezaug "10.semedepset#$semedepset\n";
		$semehitzset =~ s/\%//g;
		print $fezaug "11.semehitzset#$semehitzset\n";
		if ($semelemaset eq "") {
		    $semelemaset = "-";
		}
		$semelemaset =~ s/\%//g;
		print $fezaug "12.semelemaset#$semelemaset\n";
		my $kasua = "-";
		my $irakurtzekoa = "";
		if ($izs ne "") {
		    $irakurtzekoa = "$dir_kasufitx/$fitx_izena1";
		}
		else {
		    $irakurtzekoa = "$dir_kasufitx/$fitx_izena";
		}
		$irakurtzekoa =~ s/conll09/conll/g;
		if (-e $irakurtzekoa) {
		    open my $fkasuf, "<:encoding(UTF-8)", $irakurtzekoa or die "Ezin da $irakurtzekoa fitxategia ireki-3: $!\n";
		    my $aurreko2_kasu = "";
		    my $aurreko_kasu = "";
		    my $uneko_kasu = "";
		    while (my $lerroa_kasu = <$fkasuf>) {
			chomp($lerroa_kasu);
			$aurreko2_kasu = $aurreko_kasu;
			$aurreko_kasu = $uneko_kasu;
			$uneko_kasu = $lerroa_kasu;
			$uneko_kasu =~ s/^\s*//;
			$uneko_kasu =~ s/\s*$//;
			my @zati_kasu = split(/\t/, $uneko_kasu);
			if ($zati_kasu[0] eq $hitz_zenb) {
			    my @zati_kasu2 = split(/\n/, $zati_kasu[3]);
			    $kasua = $zati_kasu2[0];
			}
		    }
		    close $fkasuf or die "Ezin da $irakurtzekoa fitxategia itxi: $!\n";
		    print $fezaug "14.kasua#$kasua\n";
		}
		else {
		    print $fezaug "14.kasua#$kasua\n";
		}
		print $fezaug "13.Klasea#$klasea\n";
		close $fezaug or die "Ezin da $fezaug fitxategia itxi: $!\n";
	    }
	}
	close $ftrain or die "Ezin da $ftrain fitxategia itxi: $!\n";
    }
}


sub aurreprozesatu {
    my ($pId, $dir) = @_;
    my $dir_prozg = "$dir/tmp/$pId/Ezaugarriak_Desanb_$pId";
    my $dir_prozesatuta = "$dir/tmp/$pId/Ezaugarriak_Desanb_Aurreprozesatuta_$pId";
    if (-d $dir_prozesatuta) {
	system("rm -rf $dir_prozesatuta");
    }
    system("mkdir $dir_prozesatuta");

    my $dir_lex = "$dir/resources/files_PD/Lexikoia.txt";
    my $dir_adibak = "$dir/resources/files_PD/AdieraBakarrekoak.txt";
    my $kont = 0;
    foreach my $fp (glob("$dir_prozg/*")) {
	open my $ffitx, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki: $!\n";
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_izena = $zatiak_bidea[$KOKZ];
	my $uneko_pred = "";
	my $aurreko2_lerroa = "";
	my $aurreko_lerroa = "";
	my $uneko_lerroa = "";
	while (my $lerroa = <$ffitx>) {
	    chomp($lerroa);
	    $aurreko2_lerroa = $aurreko_lerroa;
	    $aurreko_lerroa = $uneko_lerroa;
	    $uneko_lerroa = $lerroa;
	    $uneko_lerroa =~ s/^\s*//;
	    $uneko_lerroa =~ s/\s*$//;
	    if ($uneko_lerroa =~ m/^2\./) {
		my @zat_pred = split(/\#/, $uneko_lerroa);
		$uneko_pred = uc($zat_pred[1]);
	    }
	}
	close $ffitx or die "Ezin da $fp fitxategia itxi: $!\n";

	open my $fadibak, "<:encoding(UTF-8)", $dir_adibak or die "Ezin da $dir_adibak fitxategia ireki: $!\n";
	my $adibakda = 0;
	my $aurreko2_ler = "";
	my $aurreko_ler = "";
	my $uneko_ler = "";
	while (my $ler = <$fadibak>) {
	    chomp($ler);
	    $aurreko2_ler = $aurreko_ler;
	    $aurreko_ler = $uneko_ler;
	    $uneko_ler = $ler;
	    $uneko_ler =~ s/^\s*//;
	    $uneko_ler =~ s/\s*$//;
	    my @zat2 = split(/\n/, $uneko_ler);
	    if ($zat2[0] eq $uneko_pred) {
		$adibakda = 1;
	    }
	}
	close $fadibak or die "Ezin da $dir_adibak fitxategia itxi: $!\n";

	if ($adibakda == 0) {
	    copy($fp, $dir_prozesatuta);
	}
	else {
	    my $helb = "$dir_prozesatuta/$fitx_izena";
	    open my $ffitx, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki: $!\n";
	    open my $fidatz, ">:encoding(UTF-8)", $helb or die "Ezin da $helb fitxategia ireki: $!\n";
	    my $aurreko2_le = "";
	    my $aurreko_le = "";
	    my $uneko_le = "";
	    while (my $le = <$ffitx>) {
		chomp($le);
		$aurreko2_le = $aurreko_le;
		$aurreko_le = $uneko_le;
		$uneko_le = $le;
		$uneko_le =~ s/^\s*//;
		$uneko_le =~ s/\s*$//;
		if ($uneko_le =~ m/^13\./) {
		    open my $flex, "<:encoding(UTF-8)", $dir_lex or die "Ezin da $dir_lex fitxategia ireki: $!\n";
		    my $aurreko2_lex = "";
		    my $aurreko_lex = "";
		    my $uneko_lex = "";
		    my $adiera = "";
		    while (my $lex = <$flex>) {
			chomp($lex);
			$aurreko2_lex = $aurreko_lex;
			$aurreko_lex = $uneko_lex;
			$uneko_lex = $lex;
			$uneko_lex =~ s/^\s*//;
			$uneko_lex =~ s/\s*$//;
			my @zat4 = split(/\n/, $aurreko2_lex);
			if (defined($zat4[0])) {
			    $logger->debug("[DEBUG-PD] $zat4[0] eta $uneko_pred eta $adiera");
			    if ($zat4[0] eq $uneko_pred) {
				$logger->debug("[DEBUG-PD] XXXXXXXXX");
				my @zat5 = split(/\n/, $uneko_lex);
				$adiera = $zat5[0];
			    }
			}
		    }
		    close $flex or die "Ezin da $dir_lex fitxategia itxi: $!\n";
		    print $fidatz "13.Klasea#$adiera\n";	
		}
		else {
		    print $fidatz "$uneko_le\n";
		}
	    }
	    close $ffitx or die "Ezin da $fp fitxategia itxi: $!\n";
	    close $fidatz or die "Ezin da $helb fitxategia itxi: $!\n";
	}
	$kont = $kont + 1;
    }
}


sub adierak_lortu_zero {
    my ($pId, $dir) = @_;
    my $dir_test_PI = "$dir/tmp/$pId/Esaldi_Berriak_PI_$pId";
    my $dir_test_PI_ezaug = "$dir/tmp/$pId/Ezaugarriak_Desanb_Aurreprozesatuta_$pId";
    my $dir_adiera_fitx1 = "$dir/tmp/$pId/Adierak_Info1_$pId.txt";
    if (-e $dir_adiera_fitx1) {
	system("rm $dir_adiera_fitx1");
    }

    open my $fdir_adiera_fitx1, ">:encoding(UTF-8)", $dir_adiera_fitx1 or die "Ezin da $dir_adiera_fitx1 fitxategia ireki-0: $!\n";
    foreach my $fp (glob("$dir_test_PI/*")) {
	open my $ftestpi, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_izena = $zatiak_bidea[$KOKZ];
	my $kont_predfitx = 0;
	my $aurreko2_lerroa = "";
	my $aurreko_lerroa = "";
	my $uneko_lerroa = "";
	while (my $lerroa = <$ftestpi>) {
	    chomp($lerroa);
	    $aurreko2_lerroa = $aurreko_lerroa;
	    $aurreko_lerroa = $uneko_lerroa;
	    $uneko_lerroa = $lerroa;
	    $uneko_lerroa =~ s/^\s*//;
	    $uneko_lerroa =~ s/\s*$//;
	    my @ler_zat = split(/\#/, $uneko_lerroa);
	    my @ler_zat1 = split(/\t/, $uneko_lerroa);
	    if ($uneko_lerroa =~ m/\#1/) {
		my $hitz_zenb = $ler_zat1[0];
		my $ezaug_fitx = "$dir_test_PI_ezaug/$fitx_izena.$hitz_zenb.Ezaugarriak";
		my $ezaug_fitx1 = "$fitx_izena.$hitz_zenb.Ezaugarriak";
		open my $flemalor, "<:encoding(UTF-8)", $ezaug_fitx or die "Ezin da $ezaug_fitx fitxategia ireki-2: $!\n";
		my $aurreko2_ler = "";
		my $aurreko_ler = "";
		my $uneko_ler = "";
		my $lema = "";
		while (my $ler = <$flemalor>) {
		    chomp($ler);
		    $aurreko2_ler = $aurreko_ler;
		    $aurreko_ler = $uneko_ler;
		    $uneko_ler = $ler;
		    $uneko_ler =~ s/^\s*//;
		    $uneko_ler =~ s/\s*$//;
		    if ($uneko_ler =~ m/^2\./) {
			my @lemaler_zat = split(/\#/, $uneko_ler);
			$lema = $lemaler_zat[1];
		    }
		}
		close $flemalor or die "Ezin da $flemalor fitxategia itxi: $!\n";
		print $fdir_adiera_fitx1 "$lema#$ezaug_fitx1\n";	
	    }
	}
	close $ftestpi or die "Ezin da $ftestpi fitxategia itxi: $!\n";
    }
    close $fdir_adiera_fitx1 or die "Ezin da $fdir_adiera_fitx1 fitxategia itxi: $!\n";
}


sub itzuli_zero {
    my ($predlema, $pId, $dir) = @_;
    my $irt_dir = "$dir/tmp/$pId/3_Itzulpena_$pId/$predlema.html";
    open my $firteera, ">:encoding(UTF-8)", $irt_dir or die "Ezin da $irt_dir fitxategia ireki: $!\n";
    my $URL = "http://hiztegiak.elhuyar.eus/eu_en/$predlema";
    my $agent = LWP::UserAgent->new(env_proxy => 1,keep_alive => 1, timeout => 30);
    my $header = HTTP::Request->new(GET => $URL);
    my $request = HTTP::Request->new('GET', $URL, $header);
    my $response = $agent->request($request);
    if ($response->is_success) {
	print $firteera $response->headers_as_string;
	print $firteera $response->as_string;
    }
    elsif ($response->is_error) {
	$logger->error("ERROR-PD: $URL");
	print $response->error_as_HTML;
    }
    close $firteera or die "Ezin da $firteera fitxategia itxi: $!\n";
}


sub itzulpena_garbitu {
    my ($predlema, $pId, $dir) = @_;
    my $itzulpena= "$dir/tmp/$pId/3_Itzulpena_$pId/$predlema.html";
    open my $fitzulz, "<:encoding(UTF-8)", $itzulpena or die "Ezin da $itzulpena fitxategia ireki: $!\n";
    my $itzulpena_garbi= "$dir/tmp/$pId/3_Itzulpena_Garbi_$pId/$predlema\_Garbi.txt";
    open my $fitzulg, ">:encoding(UTF-8)", $itzulpena_garbi or die "Ezin da $itzulpena_garbi fitxategia ireki: $!\n";
    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$fitzulz>) {
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	if ($uneko =~ m/\<a\shref\=\"\#\"\sonclick\=\'erakutsi\_sarrera\_berria/) {
	    my @zati = split(/\<strong\>/, $uneko);
	    foreach my $elem (@zati) {
		my @zati1 = split(/erakutsi\_sarrera\_berria\(\"/, $elem);
		if ($zati1[0] =~ m/<\/strong><\/a>/) {
		    my @zati2 = split(/\<\/strong\>\<\/a\>/, $zati1[0]);
		    if ($zati2[0] =~ m/^to\s/) {
			my @zati3 = split(/to\s/, $zati2[0]);
			print $fitzulg "$zati3[1]\n";
		    }
		    else {
			print $fitzulg "$zati2[0]\n";
		    }
		}
	    }
	}
    }
    close $fitzulz or die "Ezin da $fitzulz fitxategia itxi: $!\n";
    close $fitzulg or die "Ezin da $fitzulg fitxategia itxi: $!\n";
}


sub adierak_lortu_bat {
    my ($pId, $dir) = @_;
    my $dir_infobat = "$dir/tmp/$pId/Adierak_Info1_$pId.txt";
    my $dir_itzul = "$dir/tmp/$pId/3_Itzulpena_$pId";
    if (-d $dir_itzul) {
	system("rm -rf $dir_itzul");
    }
    system("mkdir $dir_itzul");
    my $dir_itzul_g = "$dir/tmp/$pId/3_Itzulpena_Garbi_$pId";
    if (-d $dir_itzul_g) {
	system("rm -rf $dir_itzul_g");
    }
    system("mkdir $dir_itzul_g");
    my $dir_adierak = "$dir/tmp/$pId/Adierak_Lortuta_$pId.txt";
    if (-e $dir_adierak) {
	system("rm $dir_adierak");
    }
    my $dir_lexikoia = "$dir/resources/files_PD/Lexikoia.txt";
    my $dir_bakar = "$dir/resources/files_PD/AdieraBakarrekoak.txt";
    open my $fdir_infobat, "<:encoding(UTF-8)", $dir_infobat or die "Ezin da $dir_infobat fitxategia ireki-0: $!\n";
    open my $fdir_adierak, ">:encoding(UTF-8)", $dir_adierak or die "Ezin da $dir_adierak fitxategia ireki-0: $!\n";
    my $aurreko2_ler = "";
    my $aurreko_ler = "";
    my $uneko_ler = "";
    while (my $ler = <$fdir_infobat>) {
	chomp($ler);
	$aurreko2_ler = $aurreko_ler;
	$aurreko_ler = $uneko_ler;
	$uneko_ler = $ler;
	$uneko_ler =~ s/^\s*//;
	$uneko_ler =~ s/\s*$//;
	my @ler_zat = split(/\#/, $uneko_ler);
	my $predlema = $ler_zat[0];
	my $adierakop = 0;
	if ($predlema eq ",") {
	    $predlema = "koma";
	    $adierakop = 999;
	}
	my $predlemauc = uc($predlema);
	open my $fdir_lexikoia, "<:encoding(UTF-8)", $dir_lexikoia or die "Ezin da $dir_lexikoia fitxategia ireki-0: $!\n";
	my $aurreko2_le = "";
	my $aurreko_le = "";
	my $uneko_le = "";
	my $badago = 0;
	while (my $le = <$fdir_lexikoia>){
	    chomp($le);
	    $aurreko2_le = $aurreko_le;
	    $aurreko_le = $uneko_le;
	    $uneko_le = $le;
	    $uneko_le =~ s/^\s*//;
	    $uneko_le =~ s/\s*$//;
	    if ($uneko_le eq $predlemauc) {
		$badago = 1;
		open my $fdir_bakar, "<:encoding(UTF-8)", $dir_bakar or die "Ezin da $dir_bakar fitxategia ireki-0: $!\n";
		my $aurreko2_bak = "";
		my $aurreko_bak = "";
		my $uneko_bak = "";
		while (my $le = <$fdir_bakar>) {
		    chomp($le);
		    $aurreko2_bak = $aurreko_bak;
		    $aurreko_bak = $uneko_bak;
		    $uneko_bak = $le;
		    $uneko_bak =~ s/^\s*//;
		    $uneko_bak =~ s/\s*$//;
		    my @zat = split(/\n/, $uneko_bak);
		    if ($zat[0] eq $predlemauc) {
			$adierakop = 1;
		    }
		}
		close $fdir_bakar or die "Ezin da $dir_bakar fitxategia itxi: $!\n";
	    }
	}
	close $fdir_lexikoia or die "Ezin da $dir_lexikoia fitxategia itxi: $!\n";
	if (($predlema ne "koma")&&($badago == 0)) {
	    itzuli_zero($predlema, $pId, $dir);
	    itzulpena_garbitu($predlema, $pId, $dir);
	}
	print $fdir_adierak "$uneko_ler#$badago#$adierakop\n";
    }
    close $fdir_infobat or die "Ezin da $dir_infobat fitxategia itxi: $!\n";
    close $fdir_adierak or die "Ezin da $dir_adierak fitxategia itxi: $!\n";
}


sub adierak_lortu_bi {
    my ($pId, $dir) = @_;
    my $dir_garbiak = "$dir/tmp/$pId/3_Itzulpena_Garbi_$pId";
    my $dir_garbiak_cp = "$dir/tmp/$pId/3_Itzulpena_Garbi1_$pId";
    if (-d $dir_garbiak_cp) {
	system("rm -rf $dir_garbiak_cp");
    }
    system("mkdir $dir_garbiak_cp");
    my $dir_lortuta = "$dir/tmp/$pId/Adierak_Lortuta_$pId.txt";
    my $dir_pb = "$dir/resources/files_PD/PB_1.7";
    my %hash = ();
    foreach my $fp (glob("$dir_garbiak/*")) {
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_dir = "$dir_garbiak/$zatiak_bidea[$KOKZ]";	
	my @zat = split(/\_/, $zatiak_bidea[$KOKZ]);
	my $fitx_dir_nora = "$dir_garbiak_cp/$zat[0]*Garbia.txt";
	copy($fitx_dir,$fitx_dir_nora) or die "Copy-k huts egin du: $!";
    }

    open my $flortuta, "<:encoding(UTF-8)", $dir_lortuta or die "Ezin da $dir_lortuta fitxategia ireki: $!\n";
    my $aurreko2_ler = "";
    my $aurreko_ler = "";
    my $uneko_ler = "";
    while (my $ler = <$flortuta>) {
	chomp($ler);
	$aurreko2_ler = $aurreko_ler;
	$aurreko_ler = $uneko_ler;
	$uneko_ler = $ler;
	$uneko_ler =~ s/^\s*//;
	$uneko_ler =~ s/\s*$//;
	my @zatiak = split(/\#/, $uneko_ler);
	my $predlema = $zatiak[0];
	my $badago = $zatiak[2];
	if (($predlema ne ",")&&($badago == 0)) {
	    my $dag_fitx = "$dir_garbiak_cp/$predlema*Garbia.txt";
	    if ((!-z $dag_fitx)&&(-e $dag_fitx)) {
		open my $fdag, "<:encoding(UTF-8)", $dag_fitx or die "Ezin da $dag_fitx fitxategia ireki: $!\n";
		my $lehen_lerroa = <$fdag>;
		$lehen_lerroa =~ s/^\s*//;
		$lehen_lerroa =~ s/\s*$//;
		close $fdag or die "Ezin da $dag_fitx fitxategia itxi: $!\n";
		my $PBfitx_izena = "$dir_pb/$lehen_lerroa.xml";
		if (-e $PBfitx_izena) {
		    my $parser = XML::LibXML->new();
		    my $dok = $parser->parse_file($PBfitx_izena);
		    my $lehena = 0;
		    foreach my $hitza ($dok->findnodes('frameset/predicate/roleset')) {
			if ($lehena == 0) {
			    my $id = $hitza->getAttribute('id');
			    if (!exists($hash{$predlema})) {
				$hash{$predlema} = "$id";
			    }
			    $lehena = 1;
			}
		    }
		}
	    }
	}
    }
    close $flortuta or die "Ezin da $dir_lortuta fitxategia itxi: $!\n";

    my $dir_itzulp = "$dir/tmp/$pId/Itzulp_Adiera_$pId.txt";
    if (-e $dir_itzulp) {
	system("rm $dir_itzulp");
    }
    open my $fitzulp, ">:encoding(UTF-8)", $dir_itzulp or die "Ezin da $dir_itzulp fitxategia ireki: $!\n";
    foreach my $key (sort keys %hash) {
	    print $fitzulp "$key#$hash{$key}\n";
    }
    close $fitzulp or die "Ezin da $dir_itzulp fitxategia itxi: $!\n";
}


sub esaldia_adiera_anitz {
    my ($pId, $dir) = @_;
    my $dir_lortuta = "$dir/tmp/$pId/Adierak_Lortuta_$pId.txt";
    my $dir_anitz = "$dir/tmp/$pId/4_ANITZ_$pId";
    if (-d $dir_anitz) {
	system("rm -rf $dir_anitz");
    }
    system("mkdir $dir_anitz");
    open my $flortuta, "<:encoding(UTF-8)", $dir_lortuta or die "Ezin da $dir_lortuta fitxategia ireki-0: $!\n";
    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$flortuta>) {
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	if ($uneko =~ m/\#1\#0/) {
	    my @zat0 = split(/\#/, $uneko);
	    my $nondikKop = "$dir/tmp/$pId/Ezaugarriak_Desanb_Aurreprozesatuta_$pId/$zat0[1]";
	    my $noraKop = "$dir_anitz";
	    copy($nondikKop, $noraKop);
	}
    }
    close $flortuta or die "Ezin da $dir_lortuta fitxategia itxi: $!\n";
}


sub esaldia_adiera_bakar {
    my ($pId, $dir) = @_;
    my $dir_lortuta = "$dir/tmp/$pId/Adierak_Lortuta_$pId.txt";
    my $dir_lex = "$dir/resources/files_PD/Lexikoia.txt";
    my $dir_itzulpenaAD = "$dir/tmp/$pId/BAKARRAK_Adierak_$pId.txt";
    if (-e $dir_itzulpenaAD) {
	system("rm $dir_itzulpenaAD");
    }

    open my $fitzulpenaAD, ">:encoding(UTF-8)", $dir_itzulpenaAD or die "Ezin da $dir_itzulpenaAD fitxategia ireki: $!\n";
    open my $flortuta, "<:encoding(UTF-8)", $dir_lortuta or die "Ezin da $dir_lortuta fitxategia ireki-0: $!\n";
    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$flortuta>) {
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	if ($uneko =~ m/\#1\#1/) {
	    my @zat0 = split(/\#/, $uneko);
	    my $pred = uc($zat0[0]);
	    open my $flex, "<:encoding(UTF-8)", $dir_lex or die "Ezin da $dir_lex fitxategia ireki-0: $!\n";
	    my $aurreko2_ad = "";
	    my $aurreko_ad = "";
	    my $uneko_ad = "";
	    while (my $lerroa_ad = <$flex>) {
		chomp($lerroa_ad);
		$aurreko2_ad = $aurreko_ad;
		$aurreko_ad = $uneko_ad;
		$uneko_ad = $lerroa_ad;
		$uneko_ad =~ s/^\s*//;
		$uneko_ad =~ s/\s*$//;
		my @zat = split(/\n/, $uneko_ad);
		if ($pred eq $zat[0]) {
		    my $hurrengo_lerroa = <$flex>;
		    my $hurrengo2_lerroa = <$flex>;
		    my @zat2 = split(/\n/, $hurrengo2_lerroa);
		    $zat2[0] =~ s/\_/\./g; 
		    print $fitzulpenaAD "$zat0[1]#$zat2[0]\n";
		}
	    }
	    close $flex or die "Ezin da $dir_lex fitxategia itxi: $!\n";
	}
    }
    close $flortuta or die "Ezin da $dir_lortuta fitxategia itxi: $!\n";
    close $fitzulpenaAD or die "Ezin da $dir_itzulpenaAD fitxategia itxi: $!\n";
}


sub esaldia_adiera_itzulp {
    my ($pId, $dir) = @_;
    my $dir_lortuta = "$dir/tmp/$pId/Adierak_Lortuta_$pId.txt";
    my $dir_itzulp = "$dir/tmp/$pId/Itzulp_Adiera_$pId.txt";
    my $dir_itzulpenaAD = "$dir/tmp/$pId/ITZULPEN_Adierak_$pId.txt";
    if (-e $dir_itzulpenaAD) {
	system("rm $dir_itzulpenaAD");
    }
    open my $fitzulpenaAD, ">:encoding(UTF-8)", $dir_itzulpenaAD or die "Ezin da $dir_itzulpenaAD fitxategia ireki: $!\n";
    open my $flortuta, "<:encoding(UTF-8)", $dir_lortuta or die "Ezin da $dir_lortuta fitxategia ireki-0: $!\n";
    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$flortuta>) {
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	if ($uneko =~ m/\#0\#0/) {
	    my @zat0 = split(/\#/, $uneko);
	    open my $fitzulp, "<:encoding(UTF-8)", $dir_itzulp or die "Ezin da $dir_itzulp fitxategia ireki-0: $!\n";
	    my $aurreko2_ad = "";
	    my $aurreko_ad = "";
	    my $uneko_ad = "";
	    while (my $lerroa_ad = <$fitzulp>) {
		chomp($lerroa_ad);
		$aurreko2_ad = $aurreko_ad;
		$aurreko_ad = $uneko_ad;
		$uneko_ad = $lerroa_ad;
		$uneko_ad =~ s/^\s*//;
		$uneko_ad =~ s/\s*$//;
		my @zat = split(/\#/, $uneko_ad);
		if ($zat0[0] eq $zat[0]) {
		    print $fitzulpenaAD "$zat0[1]#$zat[1]\n";
		}
	    }
	    close $fitzulp or die "Ezin da $dir_itzulp fitxategia itxi: $!\n";
	}
    }
    close $flortuta or die "Ezin da $dir_lortuta fitxategia itxi: $!\n";
    close $fitzulpenaAD or die "Ezin da $dir_itzulpenaAD fitxategia itxi: $!\n";
}


sub sortu_test_PD {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/4_ANITZ_$pId";
    my $dir_hiztegia = "$dir/resources/ML_PD/Hiztegia.txt";
    my $dir_hiztegi_b = "$dir/tmp/$pId/Hiztegi_Berria_PD_$pId.txt";
    if (-e $dir_hiztegi_b) {
	system("rm $dir_hiztegi_b");
    }

    my %hash = ();
    open my $fhizt, "<", $dir_hiztegia or die "Ezin da $dir_hiztegia fitxategia ireki-0: $!\n";
    my $kont = 1;
    my $aurreko2_hizt = "";
    my $aurreko_hizt = "";
    my $uneko_hizt = "";
    while (my $lerroa_hizt = <$fhizt>) {
	chomp($lerroa_hizt);
	$aurreko2_hizt = $aurreko_hizt;
	$aurreko_hizt = $uneko_hizt;
	$uneko_hizt = $lerroa_hizt;
	$uneko_hizt =~ s/^\s*//;
	$uneko_hizt =~ s/\s*$//;
	my @zati = split(/\n/, $uneko_hizt);
	$hash{$zati[0]} = $kont;
	$kont = $kont + 1;
    }
    close $fhizt or die "Ezin da $dir_hiztegia fitxategia itxi: $!\n";

    my $kontg = 1;
    my $kontug = $kont;
    foreach my $fp (glob("$dir_test/*")) {
	open my $ftest, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my $aurreko2_test = "";
	my $aurreko_test = "";
	my $uneko_test = "";
	while (my $lerroa_test_hash = <$ftest>) {
	    chomp($lerroa_test_hash);
	    $aurreko2_test = $aurreko_test;
	    $aurreko_test = $uneko_test;
	    $uneko_test = $lerroa_test_hash;
	    $uneko_test =~ s/^\s*//;
	    $uneko_test =~ s/\s*$//;
	    if (($uneko_test !~ m/^0\./)&&($uneko_test !~ m/^13\./)) {
		my @zatiak = split(/\#/, $uneko_test);
		my @zati3 = split(/\./, $zatiak[0]);
		my $gak = "$zatiak[1]#$zati3[0]";
		if (!exists($hash{$gak})) {
		    $hash{$gak} = $kontug;
		    $kontug = $kontug + 1;
		}
	    }
	}
	close $ftest or die "Ezin da $fp fitxategia itxi: $!\n";
	$kontg = $kontg + 1;
    }

    open my $fhiztb, ">:encoding(UTF-8)", $dir_hiztegi_b or die "Ezin da $dir_hiztegi_b fitxategia ireki-0: $!\n";
    foreach my $key (sort { $hash{$a} <=> $hash{$b} } keys %hash) {
	print $fhiztb "$key\n";
    }
    close $fhiztb or die "Ezin da $dir_hiztegi_b fitxategia itxi: $!\n";

    my $dir_test_fitx = "$dir/tmp/$pId/Test_PD_$pId.dat";
    if (-e $dir_test_fitx) {
	system("rm $dir_test_fitx");
    }
    open my $ftestfitx, ">:encoding(UTF-8)", $dir_test_fitx or die "Ezin da $dir_test_fitx fitxategia ireki-0: $!\n";
    my $kontagailua = 1;
    foreach my $fp (glob("$dir_test/*")) {
	open my $ftest, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my $ezaugarri_lerroa = "#";
	my $klasea = 2;
	my $id = "";
	my $aurreko2_test = "";
	my $aurreko_test = "";
	my $uneko_test = "";
	while (my $lerroa_test_hash = <$ftest>) {
	    chomp($lerroa_test_hash);
	    $aurreko2_test = $aurreko_test;
	    $aurreko_test = $uneko_test;
	    $uneko_test = $lerroa_test_hash;
	    $uneko_test =~ s/^\s*//;
	    $uneko_test =~ s/\s*$//;
	    if (($uneko_test !~ m/^0\./)&&($uneko_test !~ m/^13\./)) {
		my @zatiak = split(/\#/, $uneko_test);
		my @zati4 = split(/\./, $zatiak[0]);
		my $badago = 0;
		my $bilatzekoa = "$zatiak[1]#$zati4[0]";
		if (exists($hash{$bilatzekoa})) {
		    $badago = 1;
		    $ezaugarri_lerroa .= " $hash{$bilatzekoa}:1"	
		}
	    }
	    elsif ($uneko_test =~ m/^13\./) {
		$klasea = "1";			
	    }
	    elsif ($uneko_test =~ m/^0\./) {
		my @zatiak1 = split(/\#/, $uneko_test);
		$id = $zatiak1[1];			
	    }
	}
	close $ftest or die "Ezin da $fp fitxategia itxi: $!\n";

	my @zatiak2 = split(/\#/, $ezaugarri_lerroa);
	my %hash_ezaug = ();
	$zatiak2[1] = reverse($zatiak2[1]);
	chop($zatiak2[1]);
	$zatiak2[1] = reverse($zatiak2[1]);
	my @ezaug_zatiak = split(/\s/, $zatiak2[1]);
	foreach my $elem (@ezaug_zatiak) {
	    my @zat_elem = split(/\:/, $elem);
	    $hash_ezaug{$zat_elem[0]} = $elem;
	}
	my $lerro_ord = "";
	foreach my $keyg (sort {$a<=>$b} keys %hash_ezaug) {
	    $lerro_ord .= " $hash_ezaug{$keyg}";
	}
	my $idazteko_lerroa = "$klasea$lerro_ord # $id";
	$kontagailua = $kontagailua + 1;
	print $ftestfitx "$idazteko_lerroa\n";
    }
    close $ftestfitx or die "Ezin da $dir_test_fitx fitxategia itxi: $!\n";
}


sub iragarri_PD {
    my ($pId, $dir, $svm_multiclass_exec) = @_;
    my $output = `$svm_multiclass_exec $dir/tmp/$pId/Test_PD_$pId.dat $dir/resources/ML_PD/modelPD $dir/tmp/$pId/IragarpenakPD_$pId.txt`;
    $logger->info("[INFO-PD:iragarri_PD] $output");
}


sub anitz_sortu {
    my ($pId, $dir) = @_;
    my $dir_predikzioak = "$dir/tmp/$pId/IragarpenakPD_$pId.txt";
    my $dir_test = "$dir/tmp/$pId/Test_PD_$pId.dat";
    my $dir_anitzak = "$dir/tmp/$pId/ANITZAK_Adierak_$pId.txt";
    if (-e $dir_anitzak) {
	system("rm $dir_anitzak");
    }

    my $dir_predikatuak = "$dir/resources/ML_PD/Predikatuak.txt";
    open my $fpredik, "<:encoding(UTF-8)", $dir_predikzioak or die "Ezin da $dir_predikzioak fitxategia ireki-0: $!\n";
    open my $fanitzak, ">:encoding(UTF-8)", $dir_anitzak or die "Ezin da $dir_anitzak fitxategia ireki-0: $!\n";
    open my $ftest, "<:encoding(UTF-8)", $dir_test or die "Ezin da $dir_test fitxategia ireki-0: $!\n";
    open my $fpredikatuak, "<:encoding(UTF-8)", $dir_predikatuak or die "Ezin da $dir_predikatuak fitxategia ireki-0: $!\n";
    my $aurreko2p = "";
    my $aurrekop = "";
    my $unekop = "";
    my %hash = ();
    while (my $lerroap = <$fpredikatuak>) {
	chomp($lerroap);
	$aurreko2p = $aurrekop;
	$unekop = $lerroap;
	$unekop =~ s/^\s*//;
	$unekop =~ s/\s*$//;
	my @zat = split(/\s/, $unekop);
	$hash{$zat[1]} = "$zat[0]";
    }
    close $fpredikatuak or die "Ezin da $dir_predikatuak fitxategia itxi: $!\n";

    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$fpredik>) {
	my $lerr_test = <$ftest>;
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	my @zat = split(/\n/, $uneko);
	my @zat2 = split(/\#/, $lerr_test);
	my @zat3 = split(/\n/, $zat2[1]);
	$zat3[0] = reverse($zat3[0]);
	chop($zat3[0]);
	$zat3[0] = reverse($zat3[0]);
	my $zenbakia = $zat[0];
	if (exists($hash{$zenbakia})) {
	    my $adiera = $hash{$zenbakia};
	    $adiera =~ s/\_/\./g;
	    print $fanitzak "$zat3[0]#$adiera\n";
	}
    }
    close $ftest or die "Ezin da $dir_test fitxategia itxi: $!\n";
    close $fpredik or die "Ezin da $dir_predikzioak fitxategia itxi: $!\n";
    close $fanitzak or die "Ezin da $dir_anitzak fitxategia itxi: $!\n";
}


sub bateratu_iragarpenak {
    my ($pId, $dir) = @_;
    my $dir_bak = "$dir/tmp/$pId/BAKARRAK_Adierak_$pId.txt";
    my $dir_anitz = "$dir/tmp/$pId/ANITZAK_Adierak_$pId.txt";
    my $dir_itzul = "$dir/tmp/$pId/ITZULPEN_Adierak_$pId.txt";
    my $dir_danak = "$dir/tmp/$pId/DANAK_Adierak_$pId.txt";
    if (-e $dir_danak) {
	system("rm $dir_danak");
    }

    open my $fbak, "<:encoding(UTF-8)", $dir_bak or die "Ezin da $dir_bak fitxategia ireki-0: $!\n";
    open my $fanitz, "<:encoding(UTF-8)", $dir_anitz or die "Ezin da $dir_anitz fitxategia ireki-1: $!\n";
    open my $fitzul, "<:encoding(UTF-8)", $dir_itzul or die "Ezin da $dir_itzul fitxategia ireki-2: $!\n";
    open my $fdanak, ">:encoding(UTF-8)", $dir_danak or die "Ezin da $dir_danak fitxategia ireki-3: $!\n";
    my $aurreko2_bak = "";
    my $aurreko_bak = "";
    my $uneko_bak = "";
    while (my $lerrbak = <$fbak>) {
	chomp($lerrbak);
	$aurreko2_bak = $aurreko_bak;
	$aurreko_bak = $uneko_bak;
	$uneko_bak = $lerrbak;
	$uneko_bak =~ s/^\s*//;
	$uneko_bak =~ s/\s*$//;
	print $fdanak "$uneko_bak\n";
    }
    my $aurreko2_ani = "";
    my $aurreko_ani = "";
    my $uneko_ani = "";
    while (my $lerrani = <$fanitz>) {
	chomp($lerrani);
	$aurreko2_ani = $aurreko_ani;
	$aurreko_ani = $uneko_ani;
	$uneko_ani = $lerrani;
	$uneko_ani =~ s/^\s*//;
	$uneko_ani =~ s/\s*$//;
	print $fdanak "$uneko_ani\n";
    }

    my $aurreko2_it = "";
    my $aurreko_it = "";
    my $uneko_it = "";
    while (my $lerrit = <$fitzul>) {
	chomp($lerrit);
	$aurreko2_it = $aurreko_it;
	$aurreko_it = $uneko_it;
	$uneko_it = $lerrit;
	$uneko_it =~ s/^\s*//;
	$uneko_it =~ s/\s*$//;
	print $fdanak "$uneko_it\n";
    }
    close $fdanak or die "Ezin da $dir_danak fitxategia itxi: $!\n";
    close $fitzul or die "Ezin da $dir_itzul fitxategia itxi: $!\n";
    close $fanitz or die "Ezin da $dir_anitz fitxategia itxi: $!\n";
    close $fbak or die "Ezin da $dir_bak fitxategia itxi: $!\n";
}


sub sortu_identifikaziorakoa {
    my ($pId, $dir) = @_;
    my $dir_test_or = "$dir/tmp/$pId/Esaldiak_$pId";
    my $dir_test_identif = "$dir/tmp/$pId/Identifikaziorako_$pId";
    if (-d $dir_test_identif) {
	system("rm -rf $dir_test_identif");
    }
    system("mkdir $dir_test_identif");

    my $dir_adierak = "$dir/tmp/$pId/DANAK_Adierak_$pId.txt";
    foreach my $fp (glob("$dir_test_or/*")) {
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitxizena = $zatiak_bidea[$KOKZ];
	my $helb = "$dir_test_identif/$fitxizena";
	open my $ftest, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	open my $fidentif, ">:encoding(UTF-8)", $helb or die "Ezin da $helb fitxategia ireki-1: $!\n";
	my $aurreko2_lerroa = "";
	my $aurreko_lerroa = "";
	my $uneko_lerroa = "";
	while (my $lerroa = <$ftest>) {
	    chomp($lerroa);
	    $aurreko2_lerroa = $aurreko_lerroa;
	    $aurreko_lerroa = $uneko_lerroa;
	    $uneko_lerroa = $lerroa;
	    $uneko_lerroa =~ s/^\s*//;
	    $uneko_lerroa =~ s/\s*$//;
	    my @zat = split(/\t/, $uneko_lerroa);
	    my $idazteko_lerroa = "";
	    open my $fadi, "<:encoding(UTF-8)", $dir_adierak or die "Ezin da $dir_adierak fitxategia ireki-1: $!\n";
	    if (defined($zat[0])) {
		my $bilatzekoa = "$fitxizena.$zat[0].Ezaugarriak";
		my $adiera = "-";
		my $aurreko2_le = "";
		my $aurreko_le = "";
		my $uneko_le = "";
		while (my $lerr = <$fadi>) {
		    chomp($lerr);
		    $aurreko2_le = $aurreko_le;
		    $aurreko_le = $uneko_le;
		    $uneko_le = $lerr;
		    $uneko_le =~ s/^\s*//;
		    $uneko_le =~ s/\s*$//;
		    if ($uneko_le =~ m/$bilatzekoa/) {
			my @zat2 = split(/\#/, $uneko_le);
			$adiera = "$zat2[1]";
		    }
		}
		close $fadi or die "Ezin da $dir_adierak fitxategia itxi: $!\n";
		my $kont = 0;
		my $index = 0;
		foreach my $el (@zat) {
		    if ($kont == 0) {
			$kont = 1;
			$idazteko_lerroa .= "$el";
			$index = $index + 1;
		    }
		    else {
			if ($index < 7) {
			    $idazteko_lerroa .= "\t$el";
			    $index = $index + 1;
			}
		    }
		}
		$idazteko_lerroa .= "\t$adiera";
		print $fidentif "$idazteko_lerroa\n";
	    }
	}
	close $ftest or die "Ezin da $fp fitxategia itxi: $!\n";
	close $fidentif or die "Ezin da $helb fitxategia itxi: $!\n";
    }
}

