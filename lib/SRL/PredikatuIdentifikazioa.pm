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

package SRL::PredikatuIdentifikazioa;
use strict;
use warnings;
use File::Copy qw(copy);

use Exporter qw(import);
our @EXPORT_OK = qw(erauzi_PI sortu_test_PI iragarri_PI PIak_gehitu);

my $logger = Log::Log4perl->get_logger();


sub erauzi_PI {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/Esaldiak_$pId";
    my $dir_ezaug = "$dir/tmp/$pId/Ezaugarriak_PI_$pId";
    if (-d $dir_ezaug) {
	system("rm -rf $dir_ezaug");
    }
    system("mkdir $dir_ezaug");
    
    my $dir_kasufitx = "$dir/tmp/$pId/KASUA_Conll_$pId";
    foreach my $fp (glob("$dir_test/*")) {
	open my $ftrain, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my %hash = ();
	open my $ftrain_hash, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
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
	    if (defined($gakoa)) {
		$hash{$gakoa} = $uneko_train;
	    }
	}
	close $ftrain_hash or die "Ezin da $ftrain_hash fitxategia itxi: $!\n";

	my @zatiak_bidea = split(/\//, $fp);
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
	    my @zatipunt = split(/\t/,$aurreko_lerroa_train);
	    my @ler_zat = split(/\t/, $uneko_lerroa_train);
	    if (defined($ler_zat[0])) {
		my $hitz_zenb = $ler_zat[0];
		if (($hitz_zenb eq "1")||(($hitz_zenb ne "1")&&($zatipunt[1] ne "."))) {
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
		    my $predikatua = $ler_zat[7];
		    my $klasea = 0;
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
		    my $irakurtzekoa = "$dir_kasufitx/$fitx_izena1";
		    if (-e $irakurtzekoa) {
			open my $fkasuf, "<:encoding(UTF-8)", $irakurtzekoa or die "Ezin da $irakurtzekoa fitxategia ireki-1: $!\n";
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
		    }
		    print $fezaug "13.Klasea#$klasea\n";
		    close $fezaug or die "Ezin da $fezaug fitxategia itxi: $!\n";
		}
	    }
	}
	close $ftrain or die "Ezin da $ftrain fitxategia itxi: $!\n";
    }
}


sub sortu_test_PI {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/Ezaugarriak_PI_$pId";
    my $dir_hiztegia = "$dir/resources/ML_PI/Hiztegia.txt";
    my $dir_hiztegi_b = "$dir/tmp/$pId/Hiztegi_Berria_PI_$pId.txt";
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
    close $fhizt or die "Ezin da $dir_hiztegia fitxategi itxi: $!\n";

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
	    if ($uneko_test !~ m/^0\./) {
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

    my $dir_test_fitx = "$dir/tmp/$pId/Test_PI_$pId.dat";
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
		my @zatiak1 = split(/\#/, $uneko_test);
		$klasea = $zatiak1[1];			
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
	my @ezaug_Zatiak = split(/\s/, $zatiak2[1]);
	foreach my $elem (@ezaug_Zatiak) {
	    my @zat_elem = split(/\:/, $elem);
	    $hash_ezaug{$zat_elem[0]} = $elem;
	}

	my $lerro_ord = "";
	foreach my $keyg (sort {$a<=>$b} keys %hash_ezaug) {
	    $lerro_ord .= " $hash_ezaug{$keyg}";
	}
	if ($klasea eq "0") {
	    $klasea = "-1";
	}

	my $idazteko_Lerroa = "$klasea$lerro_ord # $id";
	$kontagailua = $kontagailua + 1;
	print $ftestfitx "$idazteko_Lerroa\n";
    }
    close $ftestfitx or die "Ezin da $dir_test_fitx fitxategia itxi: $!\n";
}


sub iragarri_PI {
    my ($pId, $dir, $svm_light_exec) = @_;
    my $output = `$svm_light_exec -v 1 $dir/tmp/$pId/Test_PI_$pId.dat $dir/resources/ML_PI/modelPI $dir/tmp/$pId/IragarpenakPI_$pId.txt`;
    $logger->info("[INFO-PI:iragarri_PI] $output");
}


sub PIak_gehitu {
    my ($pId, $dir) = @_;
    my $dir_PI_Iragarpenak = "$dir/tmp/$pId/IragarpenakPI_$pId.txt";
    my $dir_test_fitx = "$dir/tmp/$pId/Test_PI_$pId.dat";
    my $dir_test_orig = "$dir/tmp/$pId/Esaldiak_$pId";
    my $dir_SVM = "$dir/tmp/$pId/Esaldi_Berriak_PI_$pId";
    if (-d $dir_SVM) {
	system("rm -rf $dir_SVM");
    }
    system("mkdir $dir_SVM");

    my %hash = ();
    open my $firagarpenak, "<:encoding(UTF-8)", $dir_PI_Iragarpenak or die "Ezin da $dir_PI_Iragarpenak fitxategia ireki-0: $!\n";
    open my $ftest, "<:encoding(UTF-8)", $dir_test_fitx or die "Ezin da $dir_test_fitx fitxategia ireki-0: $!\n";
    my $aurreko2 = "";
    my $aurreko = "";
    my $uneko = "";
    while (my $lerroa = <$ftest>) {
	my $iragarpena = <$firagarpenak>;
	chomp($lerroa);
	$aurreko2 = $aurreko;
	$aurreko = $uneko;
	$uneko = $lerroa;
	$uneko =~ s/^\s*//;
	$uneko =~ s/\s*$//;
	my @zati_hash = split(/\#/, $uneko);
	$zati_hash[1] = reverse($zati_hash[1]);
	chop($zati_hash[1]);
	$zati_hash[1] = reverse($zati_hash[1]);
	my @zati_irag = split(/\n/, $iragarpena);
	$hash{$zati_hash[1]} = $zati_irag[0];
    }
    close $ftest or die "Ezin da $dir_test_fitx fitxategia itxi: $!\n";
    close $firagarpenak or die "Ezin da $dir_PI_Iragarpenak fitxategia itxi: $!\n";

    foreach my $fp (glob("$dir_test_orig/*")) {
	open my $ftest_irak, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_izena = $zatiak_bidea[$KOKZ];
	my $direk = "$dir_SVM/$fitx_izena";
	open my $ftest_idaz, ">:encoding(UTF-8)", $direk or die "Ezin da $direk fitxategia ireki-0: $!\n";
	my $kont = 1;
	my $aurreko2 = "";
	my $aurreko = "";
	my $uneko = "";
	while (my $lerroa = <$ftest_irak>) {
	    chomp($lerroa);
	    $aurreko2 = $aurreko;
	    $aurreko = $uneko;
	    $uneko = $lerroa;
	    $uneko =~ s/^\s*//;
	    $uneko =~ s/\s*$//;
	    my $gakoa = "$fitx_izena.$kont.Ezaugarriak";
	    if (exists($hash{$gakoa})) {
		my $lerroa_idazteko = "";
		if ($hash{$gakoa} < 0) {
		    $lerroa_idazteko = "$uneko\t#0";
		}
		else {
		    $lerroa_idazteko = "$uneko\t#1";
		}
		print $ftest_idaz "$lerroa_idazteko\n";
	    }
	    $kont = $kont + 1;
	}
	close $ftest_idaz or die "Ezin da $direk fitxategia itxi: $!\n";
	close $ftest_irak or die "Ezin da $fp fitxategia itxi: $!\n";
    }
}
