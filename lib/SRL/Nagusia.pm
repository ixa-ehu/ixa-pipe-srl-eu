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

package SRL::Nagusia;
use strict;
use warnings;
use File::Copy;
use XML::LibXML;
use Sys::Hostname;
use FindBin qw($Bin);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);
use File::Path;
use lib catdir($Bin, 'lib');
use SRL::PredikatuIdentifikazioa qw(erauzi_PI sortu_test_PI iragarri_PI PIak_gehitu);
use SRL::PredikatuDesanbiguazioa qw(erauzi_PD aurreprozesatu adierak_lortu_zero adierak_lortu_bat adierak_lortu_bi esaldia_adiera_anitz esaldia_adiera_bakar esaldia_adiera_itzulp sortu_test_PD iragarri_PD anitz_sortu bateratu_iragarpenak sortu_identifikaziorakoa);
use SRL::ArgumentuIdentifikazioa qw(identifikatu);
use SRL::ArgumentuSailkapena qw(erauzi_AS sortu_test_AS iragarri_AS egokitu iragarri_AS_mega zuzendu gehitu);

use Exporter 'import';
our @EXPORT_OK = qw(egokitu_sarrera predikatu_identifikazioa predikatu_desanbiguazioa argumentu_identifikazioa argumentu_sailkapena sortu_irteera);

binmode STDOUT;

my $begin_timestamp = get_datetime();


sub get_datetime {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $nice_timestamp = sprintf ( "%04d-%02d-%02dT%02d:%02d:%02d+0100", $year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $nice_timestamp;
}


sub irakurri_dir($) {
    my($dir) = @_;
    my(@files);
    local(*DIR);
    if (!opendir(DIR, $dir)) { return () }
    @files = sort(grep(!/^(\.|\.\.)$/, readdir(DIR)));
    closedir(DIR);
    return @files
}


sub egokitu_sarrera {
    my ($pId, $dir) = @_;
    my $NAF_fitxategia = "$dir/tmp/$pId/Sarrera_Testua_$pId.xml";
    my $esaldiak_dir = "$dir/tmp/$pId/Esaldiak_$pId";
    if (-d $esaldiak_dir) {
	system("rm -rf $esaldiak_dir");
    }
    system("mkdir $esaldiak_dir");
    
    my $kasua_dir = "$dir/tmp/$pId/KASUA_Conll_$pId";
    if (-d $kasua_dir) {
	system("rm -rf $kasua_dir");
    }
    system("mkdir $kasua_dir");
    
    my $esaldi_kont = 0;
    my $parser = XML::LibXML->new();
    my $dok = $parser->parse_file($NAF_fitxategia);
    my %hash_termo = ();
    foreach my $gakot ($dok->findnodes('NAF/terms/term/span/target')) {
	my $id = $gakot->getAttribute('id');
	my $guras1 = $gakot->parentNode;
	my $guras2 = $guras1->parentNode;
	my $tid = $guras2->getAttribute('id');
	$hash_termo{$id} = "$tid";
    }
    
    my $esaldi_index = 1;
    my %esaldi_hash = ();
    my $hash_index = 1;
    my %hash_word_zenb = ();
    foreach my $hitza ($dok->findnodes('NAF/text/wf')) {
	my $uneko_index = $hitza->getAttribute('sent');
	my $uneko_id = $hitza->getAttribute('id');
	my $testua = $hitza->textContent;
	if (int($uneko_index) != $esaldi_index) {
	    $esaldi_index = $esaldi_index + 1;
	    my $uneko_dir = "$esaldiak_dir/$esaldi_kont.txt.conll09";
	    my $uneko_kasua_dir = "$kasua_dir/$esaldi_kont.txt.conll";
	    $esaldi_kont = $esaldi_kont + 1;
	    open my $fidaz, ">:encoding(UTF-8)", $uneko_dir or die "Ezin da $uneko_dir fitxategia ireki: $!\n";
	    open my $fidaz_kasua, ">:encoding(UTF-8)", $uneko_kasua_dir or die "Ezin da $uneko_kasua_dir fitxategia ireki: $!\n";
	    foreach my $gak (sort {$a <=> $b} keys %esaldi_hash) {
		my @zat = split(/\t/, $esaldi_hash{$gak});
		my @zat1 = split(/\s/, $zat[2]);
		my $kasua = "-";
		foreach my $kas (@zat1) {
		    if (($kas eq "ABS")||($kas eq "DAT")||($kas eq "INE")||($kas eq "INS")||($kas eq "GEN")||($kas eq "ERG")||($kas eq "GEL")||($kas eq "-")||($kas eq "ABL")||($kas eq "SOZ")||($kas eq "PAR")||($kas eq "DES")||($kas eq "ALA")||($kas eq "MOT")||($kas eq "ABZ")||($kas eq "ABU")||($kas eq "PRO")) {
			$kasua = "$kas";
		    }
		}
		my $idaztekoa = "-\t-";
		if (exists($zat[2])) {
		    if ($zat[2] =~ m/\s/) {
			my @zatx = split(/\s/, $zat[2]);
			$idaztekoa = "$zatx[0]\t$zatx[1]";
		    }
		    else {
			$idaztekoa = "$zat[2]\t-"
		    }
		}
		my $whitza = "-";
		my $aurkitua = 0;
		foreach my $bil (sort keys %hash_termo) {
		    if (($aurkitua == 0)&&($hash_termo{$bil} eq "$zat[4]")) {
			$whitza = "$bil";
			$aurkitua = 1;
		    }
		}
		my $lot = 0;
		if (exists($hash_word_zenb{$whitza})) {
		    $lot = "$hash_word_zenb{$whitza}";
		}
		print $fidaz "$gak\t$zat[1]\t$zat[3]\t$idaztekoa\t$lot\t$zat[5]\n";
		print $fidaz_kasua "$gak\t$zat[1]\t$zat[3]\t$kasua\n";
	    }
	    close $fidaz or die "Ezin da $uneko_dir fitxategia itxi: $!\n";
	    close $fidaz_kasua or die "Ezin da $uneko_kasua_dir fitxategia itxi: $!\n";

	    %esaldi_hash = ();
	    $hash_index = 1;
	    %hash_word_zenb = ();
	    my $info = "-";
	    my $lema = "-";
	    my $tid = "-";
	    my $from = 0;
	    my $rfunc = "ROOT";
	    foreach my $target ($dok->findnodes('NAF/terms/term/span/target')) {
		my $id_target = $target->getAttribute('id');
		if ($id_target eq $uneko_id) {
		    my $gurasoa1 = $target->parentNode;
		    my $gurasoa2 = $gurasoa1->parentNode;
		    $info = $gurasoa2->getAttribute('case');
		    $lema = $gurasoa2->getAttribute('lemma');
		    $tid = $gurasoa2->getAttribute('id');
		    foreach my $depen ($dok->findnodes('NAF/deps/dep')) {
			my $to = $depen->getAttribute('to');
			if ($to eq $tid) {
			    $from = $depen->getAttribute('from');
			    $rfunc = $depen->getAttribute('rfunc');
			}
		    }
		}
	    }
	    $esaldi_hash{$hash_index} = "$uneko_id\t$testua\t$info\t$lema\t$from\t$rfunc";
	    $hash_word_zenb{$uneko_id} = int($hash_index);
	    $hash_index = $hash_index + 1;
	}
	else {
	    my $info = "-";
	    my $lema = "-";
	    my $tid = "-";
	    my $from = 0;
	    my $rfunc = "ROOT";
	    foreach my $target ($dok->findnodes('NAF/terms/term/span/target')) {
		my $id_target = $target->getAttribute('id');
		if ($id_target eq $uneko_id) {
		    my $gurasoa1 = $target->parentNode;
		    my $gurasoa2 = $gurasoa1->parentNode;
		    $info = $gurasoa2->getAttribute('case');
		    $lema = $gurasoa2->getAttribute('lemma');
		    $tid = $gurasoa2->getAttribute('id');
		    foreach my $depen ($dok->findnodes('NAF/deps/dep')) {
			my $to = $depen->getAttribute('to');
			if ($to eq $tid) {
			    $from = $depen->getAttribute('from');
			    $rfunc = $depen->getAttribute('rfunc');
			}
		    }
		}
	    }
	    $esaldi_hash{$hash_index} = "$uneko_id\t$testua\t$info\t$lema\t$from\t$rfunc";
	    $hash_word_zenb{$uneko_id} = int($hash_index);
	    $hash_index = $hash_index + 1;
	}	
    }	
    my $uneko_dir = "$esaldiak_dir/$esaldi_kont.txt.conll09";
    my $uneko_kasua_dir = "$kasua_dir/$esaldi_kont.txt.conll";
    open my $fidaz, ">:encoding(UTF-8)", $uneko_dir or die "Ezin da $uneko_dir fitxategia ireki: $!\n";
    open my $fidaz_kasua, ">:encoding(UTF-8)", $uneko_kasua_dir or die "Ezin da $uneko_kasua_dir fitxategia ireki: $!\n";
    foreach my $gak (sort {$a <=> $b} keys %esaldi_hash) {
	my @zat = split(/\t/, $esaldi_hash{$gak});
	my @zat1 = split(/\s/, $zat[2]);
	my $kasua = "-";
	foreach my $kas (@zat1) {
	    if (($kas eq "ABS")||($kas eq "DAT")||($kas eq "INE")||($kas eq "INS")||($kas eq "GEN")||($kas eq "ERG")||($kas eq "GEL")||($kas eq "-")||($kas eq "ABL")||($kas eq "SOZ")||($kas eq "PAR")||($kas eq "DES")||($kas eq "ALA")||($kas eq "MOT")||($kas eq "ABZ")||($kas eq "ABU")||($kas eq "PRO")) {
		$kasua = "$kas";
	    }
	}
	my $idaztekoa = "-\t-";
	if (exists($zat[2])) {
	    if ($zat[2] =~ m/\s/) {
		my @zatx = split(/\s/, $zat[2]);
		$idaztekoa = "$zatx[0]\t$zatx[1]";
	    }
	    else {
		$idaztekoa = "$zat[2]\t-"
	    }
	}
	my $whitza = "-";
	my $aurkitua = 0;
	foreach my $bil (sort keys %hash_termo) {
	    if (($aurkitua == 0)&&($hash_termo{$bil} eq "$zat[4]")) {
		$whitza = "$bil";
		$aurkitua = 1;
	    }
	}
	my $lot = 0;
	if (exists($hash_word_zenb{$whitza})) {
	    $lot = "$hash_word_zenb{$whitza}";
	}
	print $fidaz "$gak\t$zat[1]\t$zat[3]\t$idaztekoa\t$lot\t$zat[5]\n";
	print $fidaz_kasua "$gak\t$zat[1]\t$zat[3]\t$kasua\n";
    }
    close $fidaz or die "Ezin da $uneko_dir fitxategia itxi: $!\n";
    close $fidaz_kasua or die "Ezin da $uneko_kasua_dir fitxategia itxi: $!\n";
}


sub predikatu_identifikazioa {
    my ($pId, $dir, $svm_light_exec) = @_;
    erauzi_PI($pId, $dir);
    sortu_test_PI($pId, $dir);
    iragarri_PI($pId, $dir, $svm_light_exec);
    PIak_gehitu($pId, $dir);
}


sub predikatu_desanbiguazioa {
    my ($pId, $dir, $svm_multiclass_exec) = @_;
    erauzi_PD($pId, $dir);
    aurreprozesatu($pId, $dir);
    adierak_lortu_zero($pId, $dir);
    adierak_lortu_bat($pId, $dir);
    adierak_lortu_bi($pId, $dir);
    esaldia_adiera_anitz($pId, $dir);
    esaldia_adiera_bakar($pId, $dir);
    esaldia_adiera_itzulp($pId, $dir);
    sortu_test_PD($pId, $dir);
    iragarri_PD($pId, $dir, $svm_multiclass_exec);
    anitz_sortu($pId, $dir);
    bateratu_iragarpenak($pId, $dir);
    sortu_identifikaziorakoa($pId, $dir);
}


sub argumentu_identifikazioa {
    my ($pId, $dir) = @_;
    identifikatu($pId, $dir);
}


sub argumentu_sailkapena {
    my ($pId, $dir, $svm_multiclass_exec, $megam_opt_exec) = @_;
    erauzi_AS($pId, $dir);
    sortu_test_AS($pId, $dir);
    iragarri_AS($pId, $dir, $svm_multiclass_exec);
    egokitu($pId, $dir);
    iragarri_AS_mega($pId, $dir, $megam_opt_exec);
    zuzendu($pId, $dir);
    gehitu($pId, $dir);
}


sub sortu_irteera {
    my ($pId, $dir) = @_;
    
    my $sar_fitx = "$dir/tmp/$pId/Sarrera_Testua_$pId.xml";
    my $etik_dir = "$dir/tmp/$pId/Etiketatuta_$pId";
    my %hash_orokorra = ();
    my $parser1 = XML::LibXML->new();
    my $dok2 = $parser1->parse_file($sar_fitx);
    my %hash_termo = ();
    foreach my $gakot ($dok2->findnodes('NAF/terms/term/span/target')) {
	my $id = $gakot->getAttribute('id');
	my $guras1 = $gakot->parentNode;
	my $guras2 = $guras1->parentNode;
	my $tid = $guras2->getAttribute('id');
	$hash_termo{$id} = "$tid";
    }

    my $esaldi_index = 1;
    my %esaldi_hash = ();
    my $hash_index = 1;
    my %hash_word_zenb = ();
    foreach my $hitza ($dok2->findnodes('NAF/text/wf')) {
	my $uneko_index = $hitza->getAttribute('sent');
	my $uneko_id = $hitza->getAttribute('id');
	my $testua = $hitza->textContent;
	if (int($uneko_index) != $esaldi_index) {
	    $esaldi_index = $esaldi_index + 1;
	    %esaldi_hash = ();
	    $hash_index = 1;
	    %hash_word_zenb = ();
	    my $info = "-";
	    my $lema = "-";
	    my $tid = "-";
	    my $from = 0;
	    my $rfunc = "ROOT";
	    foreach my $target ($dok2->findnodes('NAF/terms/term/span/target')) {
		my $id_target = $target->getAttribute('id');
		if ($id_target eq $uneko_id) {
		    my $gurasoa1 = $target->parentNode;
		    my $gurasoa2 = $gurasoa1->parentNode;
		    $info = $gurasoa2->getAttribute('case');
		    $lema = $gurasoa2->getAttribute('lemma');
		    $tid = $gurasoa2->getAttribute('id');
		    foreach my $depen ($dok2->findnodes('NAF/deps/dep')) {
			my $to = $depen->getAttribute('to');
			if ($to eq $tid) {
			    $from = $depen->getAttribute('from');
			    $rfunc = $depen->getAttribute('rfunc');
			}
		    }
		}
	    }
	    $esaldi_hash{$hash_index} = "$uneko_id\t$testua\t$info\t$lema\t$from\t$rfunc";
	    my $gakl = $esaldi_index - 1;
	    my $gakoa = "$gakl#$hash_index";
	    $hash_orokorra{$gakoa} = "$hash_termo{$uneko_id}";
	    $hash_word_zenb{$uneko_id} = int($hash_index);
	    $hash_index = $hash_index + 1;
	}
	else {
	    my $info = "-";
	    my $lema = "-";
	    my $tid = "-";
	    my $from = 0;
	    my $rfunc = "ROOT";
	    foreach my $target ($dok2->findnodes('NAF/terms/term/span/target')) {
		my $id_target = $target->getAttribute('id');
		if ($id_target eq $uneko_id) {
		    my $gurasoa1 = $target->parentNode;
		    my $gurasoa2 = $gurasoa1->parentNode;
		    $info = $gurasoa2->getAttribute('case');
		    $lema = $gurasoa2->getAttribute('lemma');
		    $tid = $gurasoa2->getAttribute('id');
		    foreach my $depen ($dok2->findnodes('NAF/deps/dep')) {
			my $to = $depen->getAttribute('to');
			if ($to eq $tid) {
			    $from = $depen->getAttribute('from');
			    $rfunc = $depen->getAttribute('rfunc');
			}
		    }
		}
	    }
	    $esaldi_hash{$hash_index} = "$uneko_id\t$testua\t$info\t$lema\t$from\t$rfunc";
	    my $gakl = $esaldi_index - 1;
	    my $gakoa = "$gakl#$hash_index";
	    $hash_orokorra{$gakoa} = "$hash_termo{$uneko_id}";
	    $hash_word_zenb{$uneko_id} = int($hash_index);
	    $hash_index = $hash_index + 1;
	}	
    }	

    my $kodeketa = "UTF-8";
    my $dok1 = XML::LibXML::Document->new("1.0",$kodeketa);
    my $NAF = $dok1->createElement('NAF');
    $NAF->setAttribute('xml:lang',"eu");
    $NAF->setAttribute('version',"2.0");
    my $nafh = $dok1->createElement('nafHeader');
    $NAF->appendChild($nafh);
    my $parser = XML::LibXML->new();
    my $dok = $parser->parse_file($sar_fitx);
    foreach my $lp ($dok->findnodes('NAF/nafHeader/linguisticProcessors')) {
	$nafh->appendChild($lp);
    }

    my $ling1 = $dok1->createElement('linguisticProcessors');
    $ling1->setAttribute('layer',"srl");
    $nafh->appendChild($ling1);
    my $lp1 = $dok1->createElement('lp');
    $lp1->setAttribute('name',"ixa-pipe-srl-eu");
    $lp1->setAttribute('beginTimestamp',$begin_timestamp);
    $lp1->setAttribute('version',"1.0.0");
    my $host = hostname;
    $lp1->setAttribute('hostname',"$host");
    $ling1->appendChild($lp1);
    foreach my $hitza ($dok->findnodes('NAF/text')) {
	$NAF->appendChild($hitza);
    }
    foreach my $terma ($dok->findnodes('NAF/terms')) {
	$NAF->appendChild($terma);
    }
    foreach my $dep ($dok->findnodes('NAF/deps')) {
	$NAF->appendChild($dep);
    }

    my $srl = $dok1->createElement('srl');
    $NAF->appendChild($srl);
    my $predk = 1;
    my $argkont = 1;
    for my $file (irakurri_dir($etik_dir)) {
	my $dir = "$etik_dir/$file";
	my @zat_izen = split(/\./, $file);
	open my $firak, "<:encoding(UTF-8)", "$dir" or die "Ezin da $dir fitxategia ireki: $!\n";
	my %pred_hash = ();
	my %arg_hash = ();
	while (my $lerroa = <$firak>) {
	    chomp($lerroa);
	    my @zat = split(/\t/, $lerroa);
	    if ($zat[7] ne "-") {
		$pred_hash{$zat[0]} = "$zat[7]#$zat[1]";
	    }
	}
	close $firak or die "Ezin da $dir fitxategia itxi: $!\n";

	my $pred_kont = 1;
	foreach my $pgak (sort {$a<=>$b} keys %pred_hash) {
	    open my $firak_uneko, "<:encoding(UTF-8)", "$dir" or die "Ezin da $dir fitxategia ireki: $!\n";
	    my $argumentuak = "";
	    my $indexa = 7 + $pred_kont;
	    while (my $lerroa_uneko = <$firak_uneko>) {
		chomp($lerroa_uneko);
		my @zat_unekoa = split(/\t/, $lerroa_uneko);
		if ($zat_unekoa[$indexa] ne "-") {
		    $argumentuak .= "$zat_unekoa[$indexa]_$zat_unekoa[0]_$zat_unekoa[1]#";
		}
	    }
	    close $firak_uneko or die "Ezin da $dir fitxategia itxi: $!\n";

	    chop($argumentuak);
	    my $giltza = "$pgak#$pred_hash{$pgak}";
	    $argumentuak .= "&$giltza"; 
	    my $kon = $indexa - 7;
	    $arg_hash{$kon} = "$argumentuak";
	    $pred_kont = $pred_kont + 1;
	}
	foreach my $gak1 (sort {$a<=>$b} keys %arg_hash) {
	    my @zat = split(/\&/, $arg_hash{$gak1});
	    my @zat1 = split(/\#/, $zat[0]);
	    my @zat2 = split(/\#/, $zat[1]);
	    my $predn = $dok1->createElement('predicate');
	    my $id = "pr$predk";
	    $predn->setAttribute('id',"$id");
	    $predk = $predk + 1;
	    $srl->appendChild($predn);
	    my $predkom = "$zat2[2]($zat2[1])";
	    my $predkomn = XML::LibXML::Comment->new($predkom);
	    $predn->appendChild($predkomn);
	    my $spanpn = $dok1->createElement('span');
	    $predn->appendChild($spanpn);
	    my $targetpn = $dok1->createElement('target');
	    my $term_idp_gakoa = "$zat_izen[0]#$zat2[0]";
	    my $idtermp = $hash_orokorra{$term_idp_gakoa};
	    $targetpn->setAttribute('id',"$idtermp");
	    $spanpn->appendChild($targetpn);
	    foreach my $argelem (@zat1) {
		my @zatar = split(/\_/, $argelem);
		my $argn = $dok1->createElement('role');
		my $id = "rl$argkont";
		$argkont = $argkont + 1;
		$argn->setAttribute('id',"$id");
		$argn->setAttribute('semRole',"$zatar[0]");
		$predn->appendChild($argn);
		my $argkom = "$zatar[2]";
		my $argkomn = XML::LibXML::Comment->new($argkom);
		$argn->appendChild($argkomn);
		my $spanan = $dok1->createElement('span');
		$argn->appendChild($spanan);
		my $targetan = $dok1->createElement('target');
		my $term_ida_gakoa = "$zat_izen[0]#$zatar[1]";
		my $idterma = $hash_orokorra{$term_ida_gakoa};
		$targetan->setAttribute('id',"$idterma");
		$spanan->appendChild($targetan);	
	    }
	}
    }
    my $end_timestamp = get_datetime();
    $lp1->setAttribute('endTimestamp',$end_timestamp);

    $dok1->setDocumentElement($NAF);
    $dok1->toFH(\*STDOUT, 1);

    rmtree("$dir/tmp/$pId");

}

