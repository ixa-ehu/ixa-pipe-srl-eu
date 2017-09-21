#!/usr/bin/perl -w

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

use strict;
use warnings;
use encoding 'utf8';

use FindBin qw($Bin);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catdir);
use File::Path;
use Log::Log4perl qw(:easy);
use lib catdir($Bin, 'lib');
use SRL::Nagusia qw(egokitu_sarrera predikatu_identifikazioa predikatu_desanbiguazioa argumentu_identifikazioa argumentu_sailkapena sortu_irteera);

use Getopt::Std;

my %opts;
getopts('d:i:l:m:o:', \%opts);

my $dir = $opts{'d'};
my $pid = $opts{'i'};
my $svm_light_exec = $opts{'l'} ? $opts{'l'} : "./svm_light/svm_classify";
my $svm_multiclass_exec = $opts{'m'} ? $opts{'m'} : "./svm_multiclass/svm_multiclass_classify";
my $megam_opt_exec = $opts{'o'} ? $opts{'o'} : "./megam_i686.opt";

&usage("Errorea: dir-a falta") unless -d $dir;
&usage("Errorea: id-a falta") unless $pid;
&usage("Errorea: MEGA model optimization $megam_opt_exec exekutagarria falta") unless -f $megam_opt_exec;

my $svm_light_message = &try_svm($svm_light_exec);
&usage("Errorea: ezin da exekutatu $svm_light_exec") unless $svm_light_message;

my $svm_multiclass_message = &try_svm($svm_multiclass_exec);
&usage("Errorea: ezin da exekutatu $svm_multiclass_exec") unless $svm_multiclass_message;



Log::Log4perl->easy_init($WARN); # FATAL, ERROR, WARN, INFO, DEBUG, TRACE


if (-e "$dir/tmp/$pid" and -d "$dir/tmp/$pid"){
    rmtree("$dir/tmp/$pid");
}

unless(mkdir "$dir/tmp/$pid"){
    die "Ezin izan da $dir/tmp/$pid karpeta sortu: $!\n";
}


open (my $firt,">:encoding(UTF-8)", "$dir/tmp/$pid/Sarrera_Testua_$pid.xml") or die "Ezin da ireki idazketarako $dir/tmp/$pid/Sarrera_Testua_$pid.xml: $!\n";
while (<STDIN>) {
    print $firt $_;
}
close $firt;

egokitu_sarrera($pid, $dir);
predikatu_identifikazioa($pid, $dir, $svm_light_exec);
predikatu_desanbiguazioa($pid, $dir, $svm_multiclass_exec);
argumentu_identifikazioa($pid, $dir);
argumentu_sailkapena($pid, $dir, $svm_multiclass_exec, $megam_opt_exec);
sortu_irteera($pid, $dir);


sub try_svm {
  my $cmd = shift;
  my $help = qx($cmd --h);
  my $ok = ($? == 0);
  chomp $help;
  return "" unless $ok;
  return $help;
}


sub usage {
  my $str = shift;

  print $str."\n";
  die "usage: $0 -d dir -i unique_id -l svm_light_executable -m svm_multiclass_executable -o megam_opt_executable\n";

}
