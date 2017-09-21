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

package SRL::ArgumentuIdentifikazioa;
use strict;
use warnings;
use File::Copy qw(copy);
use SRL::Nagusia;

use Exporter qw(import);
our @EXPORT_OK = qw(identifikatu);

my $logger = Log::Log4perl->get_logger();



sub identifikatu {
    my ($pId, $dir) = @_;
    my $dir_train_or = "$dir/tmp/$pId/Identifikaziorako_$pId";
    my $dir_train_heur = "$dir/tmp/$pId/Identifikatuak_$pId";
    if (-d $dir_train_heur) {
	system("rm -rf $dir_train_heur");
    }
    system("mkdir $dir_train_heur");

    foreach my $fp (glob("$dir_train_or/*")) {
	my @zatiak_bidea = split(/\//, $fp);
	my $KOKZ = scalar(@zatiak_bidea) - 1;
	my $fitxizena = $zatiak_bidea[$KOKZ];
	open my $ftrain, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	my %uneko_hash = ();
	my $aurreko2_lerroa = "";
	my $aurreko_lerroa = "";
	my $uneko_lerroa = "";
	my $kont = 1;
	while (my $lerroa = <$ftrain>) {
	    chomp($lerroa);
	    $aurreko2_lerroa = $aurreko_lerroa;
	    $aurreko_lerroa = $uneko_lerroa;
	    $uneko_lerroa = $lerroa;
	    $uneko_lerroa =~ s/^\s*//;
	    $uneko_lerroa =~ s/\s*$//;
	    my @zat = split(/\t/, $uneko_lerroa);
	    if ($zat[7] =~ m/\./) {
		$uneko_hash{$kont} = "$zat[0]#$zat[7]";
		$kont = $kont + 1;
	    }
	}
	close $ftrain or die "Ezin da $fp fitxategia itxi: $!\n";

	my %argumentuak_hash = ();
	foreach my $elem (sort keys %uneko_hash) {
	    my @zat2 = split(/\#/, $uneko_hash{$elem});
	    my $giltza = "$elem#$uneko_hash{$elem}";
	    open my $ftrain, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	    my $aurreko2_lerroa = "";
	    my $aurreko_lerroa = "";
	    my $uneko_lerroa = "";
	    my $deusez = 0;
	    while (my $lerroa = <$ftrain>) {
		chomp($lerroa);
		$aurreko2_lerroa = $aurreko_lerroa;
		$aurreko_lerroa = $uneko_lerroa;
		$uneko_lerroa = $lerroa;
		$uneko_lerroa =~ s/^\s*//;
		$uneko_lerroa =~ s/\s*$//;
		my @zat = split(/\t/, $uneko_lerroa);
		if ($zat[5] eq $zat2[0]) {
		    $argumentuak_hash{$giltza} .= "#$zat[0]";
		    $deusez = 1;
		}
	    }
	    close $ftrain or die "Ezin da $fp fitxategia itxi: $!\n";

	    if ($deusez == 0) {
		$argumentuak_hash{$giltza} .= "#9999999";
	    }
	}
	$logger->debug("[DEBUG-AI] $fp");
	foreach my $elem (sort keys %argumentuak_hash) {
	    $logger->debug("[DEBUG-AI] $elem=>$argumentuak_hash{$elem}");
	}

	my $fitx_berria = "$dir_train_heur/$fitxizena";
	open my $fidaz, ">:encoding(UTF-8)", $fitx_berria or die "Ezin da $fitx_berria fitxategia ireki-1: $!\n";
	open my $ftra, "<:encoding(UTF-8)", $fp or die "Ezin da $fp fitxategia ireki-1: $!\n";
	my $aurreko2_le = "";
	my $aurreko_le = "";
	my $uneko_le = "";
	my $aurreko_lehen_zat = "";
	while (my $le = <$ftra>) {
	    chomp($le);
	    $aurreko2_le = $aurreko_le;
	    $aurreko_le = $uneko_le;
	    $uneko_le = $le;
	    $uneko_le =~ s/^\s*//;
	    $uneko_le =~ s/\s*$//;
	    my @zat = split(/\t/, $uneko_le);
	    my $lehen_zat = "$zat[0]\t$zat[1]\t$zat[2]\t$zat[3]\t$zat[4]\t$zat[5]\t$zat[6]\t$zat[7]";
	    my $uneko_zenb = $zat[0];
	    my $ind = 1;
	    foreach my $elem (sort keys %uneko_hash) {
		my $giltza = "$elem#$uneko_hash{$elem}";
		if (exists($argumentuak_hash{$giltza})) {
		    my $bada = 0;
		    my @zatiak = split(/\#/,$argumentuak_hash{$giltza});
		    foreach my $elem1 (@zatiak) {
			if ($elem1 ne "") {
			    if (($elem1 eq $uneko_zenb)&&($zat[6] ne "auxmod")&&($zat[6] ne "PUNC")&&($zat[6] ne "haos")&&	($zat[6] ne "postos")&&($zat[6] ne "entios")) {
				$logger->debug("[DEBUG-AI] BAT");
				my @zataur = split(/\t/, $aurreko_lehen_zat);
				$logger->debug("[DEBUG-AI] @zataur");
				if (defined($zataur[4])) {
				    if ($zataur[5] eq $zat[5]) {
					if ($zataur[$ind+7] =~ m/argX/) {
					    if ($zataur[4] ne "ADK") {
						$logger->debug("[DEBUG-AI] BOST");
						$lehen_zat .= "\targX";
						$bada = 1;
					    }
					}
					else {
					    $logger->debug("[DEBUG-AI] LAU");
					    $lehen_zat .= "\targX";
					    $bada = 1;
					}
				    }
				    else {
					$logger->debug("[DEBUG-AI] HIRU");
					$lehen_zat .= "\targX";
					$bada = 1;
				    }
				}
				else {
				    $lehen_zat .= "\targX";
				    $bada = 1;
				}
			    }
			}
		    }
		    if ($bada == 0) {
			$lehen_zat .= "\t-";
		    }
		    $ind = $ind + 1;
		}
	    }
	    $lehen_zat .= "\n";
	    $aurreko_lehen_zat = $lehen_zat;
	    print $fidaz "$lehen_zat";
	}
	close $ftra or die "Ezin da $fp fitxategia itxi: $!\n";
	close $fidaz or die "Ezin da $fitx_berria fitxategia itxi: $!\n";
    }
}
