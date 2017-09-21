#!/bin/sh

id=$$

# aldatu ondorengo 4 aldagai hauen balioak
# change the values of the next 4 variables
rootDir="/kokapena_katalogo_honena/ixa-pipe-srl-eu"  # path to the actual directory
svmLightExec="/kokapena_svm_light_exekutagarrira/svm_light/svm_classify"
svmMulticlassExec="/kokapena_svm_multiclass_exekutagarrira/svm_multiclass/svm_multiclass_classify"
megamOptExec="/kokapena_megam_opt_exekutagarrira/megam/megam_i686.opt"


perl $rootDir/nagusia.pl -d $rootDir -i $id -l $svmLightExec -m $svmMulticlassExec -o $megamOptExec

