# ixa-pipe-srl-eu

[**ixa-pipe-srl-eu**](http://ixa2.si.ehu.es/ixakat/ixa-pipe-srl-eu.php)
euskaraz idatzitako testuetarako rol semantikoen etiketatzailea
da. [ixaKat](http://ixa2.si.ehu.es/ixakat/index.php) kate modularreko
tresna bat da. Ikasketa automatikoan oinarritzen da eta Perl programazio
lengoaian inplementatua dago.

Tresna honek [NAF formatuan](http://wordpress.let.vupr.nl/naf/) dagoen
dokumentu bat hartzen du sarrera moduan. Sarrerako dokumentu horrek
lemak, kategoriak, informazio morfologikoa eta dependentzia etiketak
izan behar ditu. Sarreran beharreko informazio linguistiko hori duen
NAF dokumentua ondorengo ixaKat tresnek osatzen duten analisi katearen
irteeran lortzen da:

[`ixa-pipe-pos-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-pos-eu.php)
     |
[`ixa-pipe-dep-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-dep-eu.php)


## Instalazioa

Lehenik eta behin, tresnaren iturburu kodea eta exekutagarria lortu, honela: 

    git clone https://github.com/ixa-ehu/ixa-pipe-srl-eu.git

Behin hori eginda, tresna erabiltzen hasi aurretik honako urrats hauek
jarraitu beharko dituzu beharrezko baliabide eta dependentziak
instalatzeko:

 - Deskargatu baliabideen paketea hemendik:
   [srl-eu-resources-1.0.0.tgz](http://ixa2.si.ehu.es/ixakat/downloads/srl-eu-resources-1.0.0.tgz).

 - Deskonprimitu pakete hori eta kopiatu fitxategi guztiak `resources`
   direktoriora.

 - Deskargatu eta instalatu [SVM light](http://svmlight.joachims.org/)
   tresna. Eguneratu `run.sh`
   fitxategi exekutagarria `svmLightExec` aldagaiaren ondoren
   adieraziz instalatu berri duzun `svm_classify` exekutagarriaren
   kokapena.

 - Deskargatu eta instalatu [SVM
multiclass](https://www.cs.cornell.edu/people/tj/svm_light/svm_multiclass.html)
tresna. Eguneratu `run.sh` fitxategi exekutagarria `svmMulticlassExec`
aldagaiaren ondoren adieraziz instalatu berri duzun
`svm_multiclass_classify` exekutagarriaren kokapena.

 - Deskargatu eta instalatu [MEGA Model
Optimization](https://www.umiacs.umd.edu/~hal/megam/version0_2/)
tresna. Eguneratu `run.sh` fitxategi exekutagarria `megamOptExec`
aldagaiaren ondoren adieraziz instalatu berri duzun `megam_i686.opt`
exekutagarriaren kokapena.

Honetaz gain, Perl (eta honen liburutegi batzuk) instalatuak eduki
beharko dituzu zure makinan.


## Nola erabili

`nagusia.pl` script-a erabili behar da **ixa-pipe-srl-eu** tresna
exekutatzeko. `nagusia.pl` komandoaren sintaxi osoa honakoa da:

    > perl nagusia.pl -d DIR -i ID -l SVM_LIGHT_EXEKUTAGARRIA -m SVM_MULTICLASS_EXEKUTAGARRIA -o MEGAM_OPT_EXEKUTAGARRIA

    argumentuak:

     -d DIR [Beharrezkoa] Zehaztu exekutagarri hau dagoen direktorioaren kokapena.

     -i ID [Beharrezkoa] Errepikatuko ez den identifikadore zenbaki bat.

     -l SVM_LIGHT_EXEKUTAGARRIA [Beharrezkoa] Zehaztu SVM ligth exekutagarriaren kokapena.

     -m SVM_MULTICLASS_EXEKUTAGARRIA [Beharrezkoa] Zehaztu SVM multiclass exekutagarriaren kokapena. 

     -o MEGAM_OPT_EXEKUTAGARRIA [Beharrezkoa] Zehaztu Megam model optimization exekutagarriaren kokapena.

`run.sh` script exekutagarria eskuragarri jarri da **ixa-pipe-srl-eu**
tresna exekutatu ahal izateko (script honek `nagusia.pl` script-ari
deitzen dio goian azaldutako beharrezko argumentu guztiekin). Erabil
dezakezu, baina exekutatu aurretik eguneratu `rootDir`,
`svmLightExec`, `svmMulticlassExec` eta `megamOptExec` aldagaiak
[instalazioa](#Instalazioa) atalean adierazitako moduan.

Tresna honek sarrera estandarretik irakurtzen du, eta sarrera horrek
UTF-8an kodetutako NAF formatuan dagoen dokumentua izan behar du,
lemak, kategoriak, informazio morfologikoa eta dependentzia etiketak
dituena (NAF-eko `text`, `terms` eta `deps` elementuak). Sarreran
beharreko informazio linguistiko hori duen NAF dokumentua ondorengo
ixaKat tresnek osatzen duten analisi katearen irteeran lortzen da:

[`ixa-pipe-pos-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-pos-eu.php)
     |
[`ixa-pipe-dep-eu`](http://ixa2.si.ehu.es/ixakat/ixa-pipe-dep-eu.php)

Hortaz, testu gordina duen fitxategi bateko rol semantikoak lortzeko,
honako komando hau erabil dezakegu:

    > cat test.txt | sh ixa-pipe-pos-eu/ixa-pipe-pos-eu.sh | sh ixa-pipe-dep-eu/run.sh | sh ixa-pipe-srl-eu/run.sh

Tresnak irteera estandarrean idatziko du, UTF-8an kodetutatako NAF
formatuan. Irteerako NAF dokumentuan `srl` elementuen bidez rol
semantikoak markatuta ageriko dira beheko adibide honetan ikus
daitekeen moduan (adibideko sarrerako esaldia honakoa da: "*Donostiako Zinemaldiko sail ofizialean lehiatuko da Handia filma.*"):

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


## Nola egin aipamena

**ixa-pipe-srl-eu** tresna erabiltzen baduzu, ondorengo lan honen aipamena
egin zure lan akademikoan mesedez:

Haritz Salaberri, Olatz Arregi, Beñat Zapirain. bRol: The parser of
Syntactic and Semantic Dependencies for Basque. In Proceedings of
Recent Advances in Natural Language Processing (RANLP-2015), Hissar,
Bulgaria, pp. 555-562. 2015. ([*bibtex*](http://ixa2.si.ehu.es/ixakat/bib/salaberri2015.bib))


## Lizentzia

**ixa-pipe-srl-eu**-rako sortu den jatorrizko kode guztia [GPL
v3](http://www.gnu.org/licenses/gpl-3.0.en.html) lizentzia librera
atxikiturik dago.

Software honek kanpoko baliabide bat erabiltzen du, eta kodearekin
batera banatzen dugu. Baliabide honek bere lizentzia du:

 * [Propbank frames](https://github.com/propbank/propbank-frames/):
   Creative Commons - Attribution-ShareAlike 4.0 International

Horretaz gain, tresna honek beste hainbat kanpoko tresna erabiltzen
ditu, baina hauen lizentzia dela eta, ez ditugu banatzen
(erabiltzaileak lortu eta instalatu beharko ditu
[instalazioa](#Instalazioa) atalean adierazitako moduan). Hauexek dira
tresna horiek eta horien copyright jabeak eta lizentziak:

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


## Kontaktua

Arantxa Otegi, arantza.otegi@ehu.eus 
