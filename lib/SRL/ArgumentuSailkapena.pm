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

package SRL::ArgumentuSailkapena;
use strict;
use warnings;
use File::Copy qw(copy);

use Exporter qw(import);
our @EXPORT_OK = qw(erauzi_AS sortu_test_AS iragarri_AS egokitu iragarri_AS_mega zuzendu gehitu);

my $logger = Log::Log4perl->get_logger();


sub erauzi_AS {
    my ($pId, $dir) = @_;
    my $dir_train = "$dir/tmp/$pId/Identifikatuak_$pId";
    my $dir_ezaug = "$dir/tmp/$pId/Ezaugarriak_ArgSailk_$pId";
    if (-d $dir_ezaug) {
	system("rm -rf $dir_ezaug");
    }
    system("mkdir $dir_ezaug");

    my $dir_kasufitx = "$dir/tmp/$pId/KASUA_Conll_$pId";
    foreach my $fp (glob("$dir_train/*")) {
	open my $ftrain, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitxizena = $zatiak_bidea[$KOKZ];
	my @zatizen = split(/\.conll09/, $fitxizena);
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
	my %hash_pred = ();
	my %hash_pred_lema = ();
	my $hash_kont = 0;
	my $aurreko2_train = "";
	my $aurreko_train = "";
	my $uneko_train = "";
	while (my $lerroa = <$ftrain>) {
	    chomp($lerroa);
	    $aurreko2_train = $aurreko_train;
	    $aurreko_train = $uneko_train;
	    $uneko_train = $lerroa;
	    $uneko_train =~ s/^\s*//;
	    $uneko_train =~ s/\s*$//;
	    my @zatiak = split(/\t/, $uneko_train);
	    if (!defined($zatiak[7])) {
		$zatiak[7] = "-";
	    }
	    if ($zatiak[7] ne "-") {
		$hash_pred{$hash_kont} = "$zatiak[7]";
		$hash_pred_lema{$hash_kont} = "$zatiak[2]";
		$hash_kont = $hash_kont + 1;
	    }
	}
	close $ftrain or die "Ezin da $fp fitxategia itxi: $!\n";
	open my $ftrain2, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	my $aurreko2_train2 = "";
	my $aurreko_train2 = "";
	my $uneko_train2 = "";
	while (my $lerroa2 = <$ftrain2>) {
	    chomp($lerroa2);
	    $aurreko2_train2 = $aurreko_train2;
	    $aurreko_train2 = $uneko_train2;
	    $uneko_train2 = $lerroa2;
	    $uneko_train2 =~ s/^\s*//;
	    $uneko_train2 =~ s/\s*$//;
	    my @zatiak2 = split(/\t/, $uneko_train2);
	    my $kont = 0;
	    foreach my $elem (@zatiak2) {
		if (($kont > 7)&&($elem ne "-")&&($elem ne "BAL")) {
		    my $adiera_zenb = $kont - 8;
		    if ((exists($hash_pred{$adiera_zenb}))&&(exists($hash_pred_lema{$adiera_zenb}))) {
			my $bidea = "$dir_ezaug/$fitxizena.$zatiak2[0].$kont.Ezaug";
			open my $fezaug, ">:encoding(UTF-8)", $bidea or die "Ezin da $bidea fitxategia ireki-2: $!\n";
			print $fezaug "0.ID#$fitxizena.$zatiak2[0].$kont\n";
			print $fezaug "1.PBAdiera#$hash_pred{$adiera_zenb}\n";
			print $fezaug "2.PredLema#$hash_pred_lema{$adiera_zenb}\n";
			print $fezaug "3.ArgLema#$zatiak2[2]\n";
			print $fezaug "4.Kateg#$zatiak2[3]\n";
			print $fezaug "5.AzpiKateg#$zatiak2[4]\n";
			print $fezaug "6.DepRel#$zatiak2[6]\n";
			my $kasua = "-";
			my $irakurtzekoa = "";
			if ($izs ne "") {
			    $irakurtzekoa = "$dir_kasufitx/$fitx_izena1";
			}
			else {
			    $irakurtzekoa = "$dir_kasufitx/$fitxizena";
			    $irakurtzekoa =~ s/conll09/conll/g;
			}
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
				if ($zati_kasu[0] eq $zatiak2[0]) {
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
			if ($elem eq "ARGM") {
			    print $fezaug "7.Klasea#AM--\n";
			}
			else {
			    print $fezaug "7.Klasea#$elem\n";
			}			
			close $fezaug or die "Ezin da $bidea fitxategia itxi: $!\n";
		    }
		}
		$kont = $kont + 1;
	    }
	}
	close $ftrain2 or die "Ezin da $fp fitxategia itxi: $!\n";
    }
}


sub sortu_test_AS {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/Ezaugarriak_ArgSailk_$pId";
    my $dir_hiztegia = "$dir/resources/ML_AS/Hiztegia.txt";
    my $dir_hiztegi_b = "$dir/tmp/$pId/Hiztegi_Berria_AS_$pId.txt";
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
	    if (($uneko_test !~ m/^0\./)&&($uneko_test !~ m/^7\./)) {
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

    my $dir_test_fitx = "$dir/tmp/$pId/Test_AS_$pId.dat";
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
	    if (($uneko_test !~ m/^0\./)&&($uneko_test !~ m/^7\./)) {
		my @zatiak = split(/\#/, $uneko_test);
		my @zati4 = split(/\./, $zatiak[0]);
		my $badago = 0;
		my $bilatzekoa = "$zatiak[1]#$zati4[0]";
		if (exists($hash{$bilatzekoa})) {
		    $badago = 1;
		    $ezaugarri_lerroa .= " $hash{$bilatzekoa}:1"	
		}
	    }
	    elsif ($uneko_test =~ m/^7\./) {
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


sub iragarri_AS {
    my ($pId, $dir, $svm_multiclass_exec) = @_;
    my $output = `$svm_multiclass_exec $dir/tmp/$pId/Test_AS_$pId.dat $dir/resources/ML_AS/modelAS $dir/tmp/$pId/IragarpenakAS_$pId.txt`;
    $logger->info("[INFO-AS:iragarri_AS] $output");
}


sub egokitu {
    my ($pId, $dir) = @_;
    my $dir_egokitzeko = "$dir/tmp/$pId/Test_AS_$pId.dat";
    my $dir_egokituta_feat = "$dir/tmp/$pId/Test_feat_$pId.dat";
    my $dir_egokituta_id = "$dir/tmp/$pId/Test_id_$pId.dat";

    open my $firak, "<:encoding(UTF-8)", $dir_egokitzeko or die "Ezin da $dir_egokitzeko fitxategia ireki: $!\n";
    if (-e $dir_egokituta_feat) {
	system("rm $dir_egokituta_feat");
    }

    open my $fidatz_feat, ">:encoding(UTF-8)", $dir_egokituta_feat or die "Ezin da $dir_egokituta_feat fitxategia ireki: $!\n";
    if (-e $dir_egokituta_id) {
	system("rm $dir_egokituta_id");
    }

    open my $fidatz_id, ">:encoding(UTF-8)", $dir_egokituta_id or die "Ezin da $dir_egokituta_id fitxategia ireki: $!\n";
    while (my $lerroa = <$firak>) {
	my $lerro_berria = "";
	my @lerro_zati = split(/\s/, $lerroa);
	foreach my $elem (@lerro_zati) {
	    if ($elem =~ m/\:/) {
		my @zati_b = split(/\:/, $elem);
		$lerro_berria .= " F$zati_b[0]";
	    }
	    else {
		if ($elem =~ m/\./) {
		    print $fidatz_id "$elem\n";
		}
		else {
		    if ($elem !~ m/\#/) {
			my $kl = int($elem);
			$kl = $kl - 1;
			$lerro_berria .= "$kl";
		    }
		}
	    }
	}
	print $fidatz_feat "$lerro_berria\n";
    }
    close $firak or die "Ezin da $dir_egokitzeko fitxategia itxi: $!\n";
    close $fidatz_feat or die "Ezin da $dir_egokituta_feat fitxategia itxi: $!\n";
    close $fidatz_id or die "Ezin da $dir_egokituta_id fitxategia itxi: $!\n";
}


sub iragarri_AS_mega {
    my ($pId, $dir, $megam_opt_exec) = @_;
    my $output = `$megam_opt_exec -predict $dir/resources/ML_AS/modelua multiclass $dir/tmp/$pId/Test_feat_$pId.dat > $dir/tmp/$pId/Iragarpenak_AS_$pId.dat 2>&1`;
    $logger->info("[INFO-AS:iragarri_AS_mega] $output");
}


sub zuzendu {
    my ($pId, $dir) = @_;
    my $dir_test = "$dir/tmp/$pId/Test_AS_$pId.dat";
    my $dir_iragarpenak_SVM = "$dir/tmp/$pId/IragarpenakAS_$pId.txt";
    my $SVM_iragarpenak_test = "$dir/tmp/$pId/Test_iragarpenekin_SVM_$pId.dat";

    open my $firag_svm, "<:encoding(UTF-8)", $dir_iragarpenak_SVM or die "Ezin da $dir_iragarpenak_SVM fitxategia ireki: $!\n";
    open my $ftest_svm, "<:encoding(UTF-8)", $dir_test or die "Ezin da $dir_test fitxategia ireki: $!\n";
    if (-e $SVM_iragarpenak_test) {
	system("rm $SVM_iragarpenak_test");
    }
    open my $fsvm_iragarpenekin, ">:encoding(UTF-8)", $SVM_iragarpenak_test or die "Ezin da $SVM_iragarpenak_test fitxategia ireki: $!\n";
    while (my $lerroa_iragarpenak = <$firag_svm>) {
	my $lerroa_test = <$ftest_svm>;
	chomp($lerroa_iragarpenak);
	chomp($lerroa_test);
	my @zatiak_irag = split(/\n/, $lerroa_iragarpenak);
	my @zatiak_test = split(/\s/, $lerroa_test);
	shift(@zatiak_test);
	my $lerro_berria = "$zatiak_irag[0]";
	foreach my $elem (@zatiak_test) {
	    if ($elem ne "") {
		$lerro_berria .= " $elem";
	    }
	}
	print $fsvm_iragarpenekin "$lerro_berria\n";
    }
    close $firag_svm or die "Ezin da $dir_iragarpenak_SVM fitxategia itxi: $!\n";
    close $ftest_svm or die "Ezin da $dir_test fitxategia itxi: $!\n";
    close $fsvm_iragarpenekin or die "Ezin da $SVM_iragarpenak_test fitxategia itxi: $!\n";	

    my %hash_MegaM_prob = ();
    my $MegaM_iragarpenak_test = "$dir/tmp/$pId/Iragarpenak_AS_$pId.dat";
    my $kont = 1;
    open my $fMegaM, "<:encoding(UTF-8)", $MegaM_iragarpenak_test or die "Ezin da $MegaM_iragarpenak_test fitxategia ireki: $!\n";
    while (my $lerroa_MegaM = <$fMegaM>) {
	chomp($lerroa_MegaM);
	my @zatiak = split(/\t/, $lerroa_MegaM);
	$hash_MegaM_prob{$kont} = $zatiak[1];
	$kont = $kont + 1;
    }
    close $fMegaM or die "Ezin da $MegaM_iragarpenak_test fitxategia itxi: $!\n";	

    my %hash = ();
    my $lerro_zenb = 1;
    my $dir_irzuz = "$dir/tmp/$pId/IragarpenakAS_ZUZ_$pId.txt";
    if (-e $dir_irzuz) {
	system("rm $dir_irzuz");
    }

    open my $firagarzuz, ">:encoding(UTF-8)", $dir_irzuz or die "Ezin da $dir_irzuz fitxategia ireki: $!\n";
    open my $firagar, "<:encoding(UTF-8)", $SVM_iragarpenak_test or die "Ezin da $SVM_iragarpenak_test fitxategia ireki: $!\n";
    while (my $lerroa_info = <$firagar>) {
	chomp($lerroa_info);
	my @zatiak = split(/\#/, $lerroa_info);
	my @zatiak1 = split(/\.conll09\./, $zatiak[1]);
	my @zatiak2 = split(/\./, $zatiak1[1]);
	my $zutabea = $zatiak2[1];
	my $hitza = $zatiak2[0];
	$zatiak1[0] = reverse($zatiak1[0]);
	chop($zatiak1[0]);
	$zatiak1[0] = reverse($zatiak1[0]);
	my $fitxizena = "$zatiak1[0].conll09";
	my @zatiak3 = split(/\s/, $zatiak[0]);
	my $balioa = $zatiak3[0];
	my $gakoa = "$fitxizena#$zutabea#$balioa";
	if (exists($hash{$gakoa})) {
	    if (($balioa eq "1")||($balioa eq "2")||($balioa eq "4")||($balioa eq "15")||($balioa eq "22")) {
		$logger->debug("[DEBUG-AS] errep");
		my @zati_prob = split(/\s/, $hash_MegaM_prob{$lerro_zenb});
		my $handiena = 0;
		my $irag_klasea = 0;
		my $irag_kont = 1;
		foreach my $el (@zati_prob) {
		    $el = $el + 0;
		    if (($handiena < $el)&&($irag_kont ne $balioa)) {
			if (($irag_kont ne "1")&&($irag_kont ne "2")&&($irag_kont ne "4")&&($irag_kont ne "15")&&($irag_kont ne "22")) {
			    $handiena = $el;
			    $irag_klasea = $irag_kont;
			}
			else {
			    my $gako_berria = "$fitxizena#$zutabea#$irag_kont";
			    if (!exists($hash{$gako_berria})) {
				$handiena = $el;
				$irag_klasea = $irag_kont;
			    }
			}
		    }
		    $irag_kont = $irag_kont + 1;
		}
		print $firagarzuz "$irag_klasea\n";
	    }
	    else {
		print $firagarzuz "$balioa\n";
	    }	
	}
	else {
	    $hash{$gakoa} = $balioa;
	    print $firagarzuz "$balioa\n";
	}
	$lerro_zenb = $lerro_zenb + 1;
    }	
    close $firagar or die "Ezin da $SVM_iragarpenak_test fitxategia itxi: $!\n";
    close $firagarzuz or die "Ezin da $dir_irzuz fitxategia itxi: $!\n";
} 


sub gehitu {
    my ($pId, $dir) = @_;
    my $dir_AS_iragarpenak = "$dir/tmp/$pId/IragarpenakAS_ZUZ_$pId.txt";
    my $dir_test_fitx = "$dir/tmp/$pId/Test_AS_$pId.dat";
    my $dir_test_orig = "$dir/tmp/$pId/Identifikatuak_$pId";
    my $dir_SVM = "$dir/tmp/$pId/Etiketatuta_$pId";
    if (-d $dir_SVM) {
	system("rm -rf $dir_SVM");
    }
    system("mkdir $dir_SVM");

    my $dir_rolak = "$dir/resources/ML_AS/Rolak.txt";
    open my $frolak, "<:encoding(UTF-8)", $dir_rolak or die "Ezin da $dir_rolak fitxategia ireki-0: $!\n";
    my %hash_rolak = ();
    my $aurreko2_rolak = "";
    my $aurreko_rolak = "";
    my $uneko_rolak = "";
    while (my $lerroa_rolak = <$frolak>) {
	chomp($lerroa_rolak);
	$aurreko2_rolak = $aurreko_rolak;
	$aurreko_rolak = $uneko_rolak;
	$uneko_rolak = $lerroa_rolak;
	$uneko_rolak =~ s/^\s*//;
	$uneko_rolak =~ s/\s*$//;
	my @zati_hash_rolak = split(/\s/, $uneko_rolak);
	$hash_rolak{$zati_hash_rolak[1]} = "$zati_hash_rolak[0]";
    }
    close $frolak or die "Ezin da $dir_rolak fitxategia itxi: $!\n";

    my %hash = ();
    open my $firagarpenak, "<:encoding(UTF-8)", $dir_AS_iragarpenak or die "Ezin da $dir_AS_iragarpenak fitxategia ireki-0: $!\n";
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
	$hash{$zati_hash[1]} = $hash_rolak{$zati_irag[0]};
    }
    close $ftest or die "Ezin da $dir_test_fitx fitxategia itxi: $!\n";
    close $firagarpenak or die "Ezin da $dir_AS_iragarpenak fitxategia itxi: $!\n";

    foreach my $fp (glob("$dir_test_orig/*")) {
	open my $ftest_irak, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-0: $!\n";
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitx_izena = $zatiak_bidea[$KOKZ];
	my $direk = "$dir_SVM/$fitx_izena";
	open my $ftest_idaz, ">:encoding(UTF-8)", $direk or die "Ezin da $direk fitxategia ireki-0: $!\n";
	my $kont_lerroa = 1;
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
	    my @zati_lerro = split(/\t/, $uneko);
	    my $kont_zutabea = 0;
	    my $lerro_berria = "";
	    foreach my $elem (@zati_lerro) {
		my $gakoa = "$fitx_izena.$kont_lerroa.$kont_zutabea";
		if (exists($hash{$gakoa})) {
		    $lerro_berria .= "\t$hash{$gakoa}";
		}
		else {
		    if ($kont_zutabea == 0) {
			$lerro_berria .= "$elem";
		    }
		    else {
			$lerro_berria .= "\t$elem";
		    }	
		} 
		$kont_zutabea = $kont_zutabea + 1;
	    }
	    print $ftest_idaz "$lerro_berria\n";
	    $kont_lerroa = $kont_lerroa + 1;
	}
	close $ftest_idaz or die "Ezin da $direk fitxategia itxi: $!\n";
	close $ftest_irak or die "Ezin da $fp fitxategia itxi: $!\n";
    }
}
