[[*euskaraz*](IRAKURRI.md)]

# ixa-pipe-srl-eu

[**ixa-pipe-srl-eu**](http://ixa2.si.ehu.es/ixakat/ixa-pipe-srl-eu.php?lang=en)
is a semantic role labeling tool for Basque written documents.  It is
a tool of the [ixaKat](http://ixa2.si.ehu.es/ixakat/index.php?lang=en)
modular chain. It is based on machine learning techniques and it is
implemented in Perl programming language.

The tool takes a document in [NAF
format](http://wordpress.let.vupr.nl/naf/). This input document should
contain lemmas, PoS tags, morphological annotations and dependency
annotations. The input NAF document containing the necessary
linguistic information could be obtained from the output of the
following ixaKat tools' chain:

[`ixa-pipe-pos-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-pos-eu.php?lang=en)
     |
[`ixa-pipe-dep-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-dep-eu.php?lang=en)


##Installation

First, get the source code of the tool:

    git clone https://github.com/ixa-ehu/ixa-pipe-srl-eu.git

After, before starting using the tool, you have to follow the next steps in
order to install the necessary resources and dependencies.

 - Download the package of the linguistic resources from the following
link:
[srl-eu-resources-1.0.0.tgz](http://ixa2.si.ehu.es/ixakat/downloads/srl-eu-resources-1.0.0.tgz).

 - Decompress the package and copy all the files to the `resources`
directory.

 - Download and install the [SVM light](http://svmlight.joachims.org/)
tool. Update the `run.sh` executable file specifying the path of the
installed `svm_classify` executable in the `svmLightExec` variable.

 - Download and install the [SVM
multiclass](https://www.cs.cornell.edu/people/tj/svm_light/svm_multiclass.html)
tool. Update the `run.sh` executable file specifying the path of the
installed `svm_multiclass_classify` executable in the
`svmMulticlassExec` variable.

 - Download and install the [MEGA Model
Optimization](https://www.umiacs.umd.edu/~hal/megam/version0_2/)
tool. Update the `run.sh` executable file specifying the path of the
installed `megam_i686.opt` executable in the `megamOptExec` variable.

Besides, Perl (and some of its libraries) should be installed in your
computer.

##How to use

The `nagusia.pl` executable is used to run the **ixa-pipe-srl-eu** tool. The
full command syntax of nagusia.pl is

    > perl nagusia.pl -d DIR -i ID -l SVM_LIGHT_EXECUTABLE -m
    SVM_MULTICLASS_EXECUTABLE -o MEGAM_OPT_EXECUTABLE

    arguments:

     -d DIR [Required] Specify the path of the directory where this
      script is placed.

     -i ID [Required] A identifier number which is not going to be
      repeated.

     -l SVM_LIGHT_EXECUTABLE [Required] Specify the path to the SVM
      light executable.

     -m SVM_MULTICLASS_EXECUTABLE [Required] Specify the path to the
      SVM multiclass executable.

     -o MEGAM_OPT_EXECUTABLE [Required] Specify the path to the Megam
      model optimization executable.


A executable `run.sh` is provided to run the **ixa-pipe-srl-eu** tool
(this script calls to the `nagusia.pl` script with all the needed
arguments explained above). You can use it, but before running it,
update the `rootDir`, `svmLightExec`, `svmMulticlassExec` and
`megamOptExec` variables as specified in the
[installation](#installation) section.

This tool reads from standard input. It should be UTF-8 encoded NAF
format, containing lemmas, PoS tags, morphological annotations and
dependency annotations (`text`, `terms` and `deps` elements of
NAF). The input NAF document containing the necessary linguistic
information could be obtained from the output of the following ixaKat
tools' chain:

[`ixa-pipe-pos-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-pos-eu.php?lang=en)
     |
[`ixa-pipe-dep-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-dep-eu.php?lang=en)

Therefore, you can obtain semantic role labels of a plain text file
using the following comand (in a single command-line):

    > cat test.txt | sh ixa-pipe-pos-eu/ixa-pipe-pos-eu.sh | sh
    ixa-pipe-dep-eu/run.sh | sh ixa-pipe-srl-eu/run.sh

The output is written to standard output and it is in UTF-8 encoding
and NAF format. In the NAF output document the semantic role labels
will be marked by `srl` elements as it is shown in the below example
(the input sentence of the example is this one: "*Donostiako
Zinemaldiko sail ofizialean lehiatuko da Handia filma.*"):

    <srl>
      <predicate id="pr1">
        <!--lehiatuko(compete.01)-->
        <span>
          <target id="t5"/>
        </span>
        <role id="rl1" semRole="ARG2">
          <!--sail-->
          <span>
            <target id="t3"/>
          </span>
        </role>
      </predicate>
      ...
    </srl>


## How to cite

If you use **ixa-pipe-srl-eu** tool, please cite the following paper in
your academic work:

Haritz Salaberri, Olatz Arregi, Beñat Zapirain. bRol: The parser of
Syntactic and Semantic Dependencies for Basque. In Proceedings of
Recent Advances in Natural Language Processing (RANLP-2015), Hissar,
Bulgaria,
pp. 555-562. 2015. ([*bibtex*](http://ixa2.si.ehu.es/ixakat/bib/salaberri2015.bib))


## License

All the original code produced for **ixa-pipe-srl-eu** is licensed
under [GPL v3](http://www.gnu.org/licenses/gpl-3.0.en.html) free
license.

This software uses a external resource, and it is distributed with the
source code. This resource has its own license:

 * [Propbank frames](https://github.com/propbank/propbank-frames/):
   Creative Commons - Attribution-ShareAlike 4.0 International

Moreover, this tool uses some third-party tools which are not
distributed due to their licenses (the user has to get and installed
as specified in the [installation](#installation) section). These are
those third-party tools and their copyright owners and licenses:

 - [SVM light](http://svmlight.joachims.org/): Copyright (C) 2000,
   Thorsten Joachims. Free for scientific use; the software must not
   be further distributed without prior permission of the author.

 - [SVM
   multiclass](https://www.cs.cornell.edu/people/tj/svm_light/svm_multiclass.html):
   Copyright (C) 2004, Thorsten Joachims. Granted free of charge for
   non-commercial research and education purposes; the software must
   not be further distributed without prior permission of the author.

 - [MEGA Model Optimization
   Package](https://www.umiacs.umd.edu/~hal/megam/version0_3/): Free
   to anyone to use it in any research.


## Contact

Arantxa Otegi, arantza.otegi@ehu.eus 
